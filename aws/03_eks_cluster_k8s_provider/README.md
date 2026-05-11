# EKS Cluster con Terraform + Provider Kubernetes + AWS Load Balancer Controller

Despliega un cluster EKS en AWS con:
- VPC dedicada, subnets públicas/privadas y dos grupos de nodos gestionados
- **AWS Load Balancer Controller** instalado automáticamente vía Helm
- **Aplicación nginx** expuesta a internet mediante un ALB gestionado por Kubernetes Ingress

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

# Paso 1: crear el cluster EKS y la VPC
terraform apply -target=module.eks -target=module.vpc

# Paso 2: desplegar el ALB Controller y la aplicación nginx
terraform apply
```

Al finalizar el segundo apply, el output `nginx_ingress_url` mostrará la URL del ALB. El ALB puede tardar ~2 min en estar activo; si el output devuelve `http://pendiente`, espera un momento y vuelve a ejecutar `terraform output`:

```bash
terraform output nginx_ingress_url
curl $(terraform output -raw nginx_ingress_url)
```

# Destrucción de la infraestructura

Terraform destruye los recursos en el orden correcto automáticamente: primero el Ingress (lo que provoca que el ALB Controller elimine el Load Balancer de AWS), luego el Helm release del controller, y finalmente el cluster. Si el destroy falla a medias y el controller ya no está activo, el LB puede quedar huérfano en AWS y habría que borrarlo manualmente desde la consola o con `aws elbv2 delete-load-balancer`.

```bash
terraform destroy
```

---

# Interacción con el cluster

## Configurar kubectl

```bash
aws eks --region $(terraform output -raw region) update-kubeconfig \
  --name $(terraform output -raw cluster_name)
```

## Verificar conexión

```bash
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
```

## Verificar el ALB Controller

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

## Verificar la aplicación nginx

```bash
kubectl get all -n nginx-app
kubectl get ingress -n nginx-app
```

---

# Dashboard web — Headlamp

Headlamp es el sucesor del Kubernetes Dashboard oficial (archivado en 2026). Se instala en el cluster con Helm y se accede mediante port-forward local.

```bash
helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
helm repo update
helm install headlamp headlamp/headlamp --namespace kube-system
```

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=headlamp
```

```bash
kubectl --namespace kube-system port-forward \
  $(kubectl get pods --namespace kube-system -l "app.kubernetes.io/name=headlamp,app.kubernetes.io/instance=headlamp" -o jsonpath="{.items[0].metadata.name}") \
  8080:4466
```

```bash
kubectl create token headlamp --namespace kube-system
```

Accede en `http://localhost:8080` y pega el token para autenticarte.

```bash
helm uninstall headlamp -n kube-system
```