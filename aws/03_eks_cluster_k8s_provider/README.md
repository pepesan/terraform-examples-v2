# EKS Cluster con Terraform + Provider Kubernetes + AWS Load Balancer Controller

Despliega un cluster EKS en AWS con:
- VPC dedicada, subnets públicas/privadas y dos grupos de nodos gestionados
- **AWS Load Balancer Controller** instalado automáticamente vía Helm
- **Blog Astro** y **Headlamp dashboard** expuestos a internet mediante un único ALB compartido, gestionado por Kubernetes Ingress con IngressGroup

Todo se gestiona con Terraform usando los providers `aws`, `kubernetes` y `helm`.

# Prerequisitos

- **Terraform >= 1.7.1**
- **AWS CLI v2** — los providers `kubernetes` y `helm` usan `aws eks get-token` para autenticarse; debe estar instalado y configurado
- **kubectl** (opcional, para inspeccionar el cluster manualmente)

# Configuración de AWS CLI

[Guía para gestionar las credenciales de AWS](https://cursosdedesarrollo.com/2020/08/infraestructura-uso-de-terraform-instalacion-y-configuraciones-basicas/)

# Copia el fichero de variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` con tu `project_name` y `region`.

# Despliegue

> **Importante:** al crear el cluster desde cero es necesario un apply en dos pasos. Los providers `kubernetes` y `helm` necesitan que el cluster exista antes de poder inicializarse.

```bash
terraform init
```

**Paso 1 — Crear el cluster EKS y la VPC:**

```bash
terraform apply -target=module.eks -target=module.vpc

aws eks --region $(terraform output -raw region) update-kubeconfig \
  --name $(terraform output -raw cluster_name)
```
Comprobar el acceso al cluster
```bash
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
```

**Paso 2 — Desplegar el ALB Controller, el blog y Headlamp:**

```bash
terraform apply
```

El output `service_urls` mostrará las URLs de todos los servicios. El ALB puede tardar ~2 min en estar activo. Si el output devuelve `http://pendiente`, el hostname aún no se ha asignado o se asignó después de que Terraform terminó; refresca el state y vuelve a consultar — puede que necesites repetirlo varias veces hasta que el ALB esté listo:

```bash
terraform apply -refresh-only
terraform output service_urls
```

O bien obtén el hostname directamente desde el Ingress:

```bash
kubectl get ingress blog -n blog -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Con ese hostname, los servicios son accesibles en:

| Servicio  | URL                                    |
|-----------|----------------------------------------|
| Blog      | `http://<hostname>/`                   |
| Headlamp  | `http://<hostname>/headlamp/`          |

Ambos comparten el mismo ALB gracias al `alb.ingress.kubernetes.io/group.name: eks-alb` definido en sus respectivos Ingress.

# Destrucción de la infraestructura

```bash
terraform destroy
```

Terraform destruye los recursos en orden: primero los Ingress (lo que provoca que el ALB Controller elimine el ALB de AWS), luego el Helm release del controller y finalmente el cluster y la VPC. El proceso normal tarda ~10-15 minutos.

## Problemas frecuentes durante el destroy

El ALB Controller gestiona recursos de AWS (ALB, Target Groups, Security Groups) **fuera del estado de Terraform**. Si el controller se elimina antes de que acabe su limpieza, esos recursos quedan huérfanos y bloquean el destroy. A continuación se documentan los tres fallos más comunes y cómo resolverlos.

### 1. Ingress atascado en Terminating (5+ min)

**Causa:** el ALB Controller pone un finalizer `ingress.k8s.aws/resources` en cada Ingress. Si el controller muere antes de procesarlo, el Ingress nunca sale de Terminating.

**Solución:** eliminar los finalizers manualmente para desbloquear la eliminación:

```bash
kubectl patch ingress headlamp -n kube-system \
  -p '{"metadata":{"finalizers":[]}}' --type=merge

kubectl patch ingress blog -n blog \
  -p '{"metadata":{"finalizers":[]}}' --type=merge
```

### 2. Namespace `blog` atascado en Terminating

**Causa:** el ALB Controller crea un recurso `TargetGroupBinding` en el namespace para vincular el Service al Target Group de AWS. Si el controller ya no está, su finalizer `elbv2.k8s.aws/resources` nunca se elimina y bloquea al namespace.

**Solución:**

```bash
# Identificar el TargetGroupBinding bloqueado
kubectl get targetgroupbindings -n blog

# Eliminar su finalizer (sustituir <name> por el nombre real)
kubectl patch targetgroupbinding <name> -n blog \
  -p '{"metadata":{"finalizers":[]}}' --type=merge
```

Si el namespace sigue bloqueado tras limpiar los finalizers de recursos internos:

```bash
kubectl get namespace blog -o json \
  | jq '.spec.finalizers = []' \
  | kubectl replace --raw /api/v1/namespaces/blog/finalize -f -
```

### 3. VPC atascada en Destroying (5+ min)

**Causa:** el ALB Controller crea Security Groups propios (prefijo `k8s-`) para el ALB y el tráfico. AWS no permite eliminar una VPC mientras tenga Security Groups asociados, y Terraform no conoce estos SGs porque los creó el controller, no Terraform.

**Solución:**

```bash
VPC_ID=<vpc-id>   # obtener del output de Terraform o del error

# Localizar los SGs huérfanos (los del controller tienen prefijo k8s-)
aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[?GroupName!='default'].{Name:GroupName,ID:GroupId}"

# Eliminarlos (el de tráfico primero para evitar DependencyViolation)
aws ec2 delete-security-group --group-id <sg-traffic-id>
aws ec2 delete-security-group --group-id <sg-alb-id>
```

Si alguno falla con `DependencyViolation`, hay una regla que referencia al otro SG; revocarla primero:

```bash
aws ec2 revoke-security-group-ingress \
  --group-id <sg-id> --source-group <other-sg-id> --protocol -1

aws ec2 delete-security-group --group-id <sg-id>
```

Una vez eliminados los SGs, la VPC se destruye en segundos.

---

# Interacción con el cluster

## Configurar kubectl

```bash
aws eks --region $(terraform output -raw region) update-kubeconfig \
  --name $(terraform output -raw cluster_name)
```

## Comprobación completa del despliegue

### 1. Estado del cluster (AWS CLI)

```bash
aws eks describe-cluster \
  --name $(terraform output -raw cluster_name) \
  --region $(terraform output -raw region) \
  --query 'cluster.{status:status,version:version,endpoint:endpoint}'
```

Resultado esperado: `"status": "ACTIVE"`

### 2. Nodos

```bash
kubectl get nodes -o wide
```

Resultado esperado: 4 nodos en estado `Ready` (2 por node group).

### 3. Pods del sistema (kube-system)

```bash
kubectl get pods -n kube-system
```

Componentes esperados en estado `Running`:

| Componente                   | Réplicas   |
|------------------------------|------------|
| aws-load-balancer-controller | 2          |
| aws-node (vpc-cni)           | 1 por nodo |
| coredns                      | 2          |
| eks-pod-identity-agent       | 1 por nodo |
| kube-proxy                   | 1 por nodo |

### 4. Blog Astro

```bash
kubectl get pods -n blog
kubectl get svc -n blog
kubectl get ingress blog -n blog -o wide
```

Resultado esperado: 2 pods `Running`, Service `ClusterIP` activo e Ingress con hostname ALB asignado.

### 5. Test HTTP del endpoint

```bash
ALB=$(kubectl get ingress blog -n blog -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -s -o /dev/null -w "%{http_code}" "http://$ALB/"
```

Resultado esperado: `200`. Si devuelve error de conexión, espera ~2 min a que el ALB termine de registrar los targets.

---

# Dashboard web — Headlamp

Headlamp es el sucesor del Kubernetes Dashboard oficial (archivado en enero de 2026). Se despliega automáticamente como parte del `terraform apply` mediante un `helm_release` en `k8s.tf`, y está expuesto públicamente a través del mismo ALB que el blog.

## Verificar que está corriendo

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=headlamp
kubectl get ingress headlamp -n kube-system -o wide
```

## Acceder al dashboard

La URL completa está disponible directamente en el output de Terraform:

```bash
terraform output service_urls
```

Accede en `http://<hostname>/headlamp/` (con barra final).

Genera un token de acceso para autenticarte:

```bash
kubectl create token headlamp --namespace kube-system
```

Pega el token en la pantalla de login de Headlamp.
