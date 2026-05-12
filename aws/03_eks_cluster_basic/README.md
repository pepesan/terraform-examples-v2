# EKS Cluster con Terraform

Despliega un cluster EKS en AWS con VPC dedicada, subnets públicas/privadas y dos grupos de nodos gestionados.

# Configuración de AWS CLI

[Guía para gestionar las credenciales de AWS](https://cursosdedesarrollo.com/2020/08/infraestructura-uso-de-terraform-instalacion-y-configuraciones-basicas/)

# Copia el fichero de variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` con tu `project_name` y `region`.

# Despliegue

```bash
terraform init
terraform plan
terraform apply
```

# Destrucción de la infraestructura

```bash
terraform destroy
```

---

# Interacción con el cluster

## 0. Instala las herramientas necesarias

### kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

### Helm (necesario solo para la Opción B — ALB Controller)

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh
helm version
```

## 1. Configurar kubectl

> Recuerda ejecutar esto en el mismo directorio del proyecto Terraform, ya que los comandos usan `terraform output`.

```bash
aws eks --region $(terraform output -raw region) update-kubeconfig \
  --name $(terraform output -raw cluster_name)
```

Esto escribe las credenciales en `~/.kube/config` y apunta tu contexto al cluster.

## 2. Verificar conexión

```bash
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
```

## 3. Desplegar una aplicación de prueba

```bash
# Crear el deployment
kubectl create deployment nginx --image=nginx

# Verificar que el pod está Running antes de continuar
kubectl get pods -l app=nginx
```

```bash
# Probar en local sin exponer al exterior
kubectl port-forward deployment/nginx 8080:80
```

Abre `http://localhost:8080` en el navegador. Cuando estés listo, `Ctrl+C` para parar el port-forward.

## 4. Exponer servicios

> **Importante:** los nodos están en **subnets privadas** y no son accesibles directamente desde internet. NodePort solo es útil desde dentro de la VPC. Para exponer servicios al exterior hay dos opciones:

## Acceso Externo desde Load Balancer

### Opción A — LoadBalancer (NLB automático)

Cuando creas un Service de tipo `LoadBalancer`, el cloud controller de AWS provisiona automáticamente un Network Load Balancer en las subnets **públicas** (que ya están tagueadas para ello) y devuelve un DNS accesible desde internet:

```bash
kubectl expose deployment nginx --port=80 --type=LoadBalancer
```

Espera hasta que `EXTERNAL-IP` tenga valor (puede tardar ~2 min). Pulsa `Ctrl+C` cuando aparezca:

```bash
kubectl get svc nginx --watch
```

Verifica el estado del LB en AWS:

```bash
aws elbv2 describe-load-balancers \
  --region $(terraform output -raw region) \
  --query 'LoadBalancers[].{Name:LoadBalancerName,State:State.Code,DNS:DNSName}' \
  --output table
```

Cuando `State` muestre `active`, prueba el acceso:

```bash
curl http://EXTERNAL-IP
```

#### Borra el servicio

Al borrar el Service de tipo LoadBalancer, Kubernetes notifica a AWS para que elimine el NLB automáticamente:

```shell
kubectl delete svc nginx
```

Puede tardar varios minutos. Confirma que el LB ha desaparecido:

```bash
aws elbv2 describe-load-balancers \
  --region $(terraform output -raw region) \
  --query 'LoadBalancers[].{Name:LoadBalancerName,State:State.Code}' \
  --output table
```

### Opción B — Ingress con ALB Controller (recomendado)

El ALB Controller es un componente que se instala en el cluster y escucha recursos `Ingress`. Cuando creas un Ingress, el controller crea un Application Load Balancer en AWS con las reglas de enrutamiento correspondientes. A diferencia del NLB de la Opción A, el ALB trabaja en capa 7 (HTTP) y permite path-based routing, host-based routing, etc.

#### 1. Crear el IAM role para el ALB Controller

El ALB Controller necesita permisos AWS para crear y gestionar Load Balancers. Se usa **EKS Pod Identity** para inyectar las credenciales directamente en el pod del controller — es el mecanismo moderno de AWS para dar permisos a pods, sin necesidad de credenciales estáticas.

En IAM hay dos conceptos separados:
- **Política** (`iam_policy.json`): define *qué acciones* puede hacer (crear ALBs, registrar targets, etc.)
- **Role** (`trust-policy.json`): define *quién puede asumir* ese role. La trust policy ya está lista y no necesita modificación — indica que solo el servicio `pods.eks.amazonaws.com` puede asumir este role, lo que restringe su uso a pods de EKS.

**Paso 1 — Crear la política IAM** con todos los permisos necesarios para gestionar ALBs:

```bash
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam/iam_policy.json
```

**Paso 2 — Crear el IAM role** con la trust policy de Pod Identity:

```bash
aws iam create-role \
  --role-name AWSLoadBalancerControllerRole \
  --assume-role-policy-document file://iam/trust-policy.json
```

**Paso 3 — Adjuntar la política al role** (unir el "qué puede hacer" con el "quién puede asumirlo"):

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws iam attach-role-policy \
  --role-name AWSLoadBalancerControllerRole \
  --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy
```

**Paso 4 — Crear la Pod Identity association**: este es el pegamento entre el mundo AWS y el mundo Kubernetes. Le dice a EKS: *"cuando arranque un pod que use el ServiceAccount `aws-load-balancer-controller` en el namespace `kube-system`, inyéctale automáticamente credenciales temporales del role anterior"*. Sin este paso, el pod existiría pero no tendría permisos para crear nada en AWS.

```bash
aws eks create-pod-identity-association \
  --cluster-name $(terraform output -raw cluster_name) \
  --region $(terraform output -raw region) \
  --namespace kube-system \
  --service-account aws-load-balancer-controller \
  --role-arn arn:aws:iam::${ACCOUNT_ID}:role/AWSLoadBalancerControllerRole
```

#### 2. Instalar el ALB Controller

Las subnets ya están tagueadas con `kubernetes.io/role/elb=1` (públicas) y `kubernetes.io/role/internal-elb=1` (privadas) para que el controller sepa en qué subnets crear los ALBs.

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update

VPC_ID=$(aws eks describe-cluster \
  --name $(terraform output -raw cluster_name) \
  --region $(terraform output -raw region) \
  --query "cluster.resourcesVpcConfig.vpcId" \
  --output text)

# serviceAccount.create=true crea el ServiceAccount en Kubernetes con el nombre
# esperado por Pod Identity (aws-load-balancer-controller); sin él el pod no
# recibe las credenciales IAM
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$(terraform output -raw cluster_name) \
  --set serviceAccount.create=true \
  --set region=$(terraform output -raw region) \
  --set vpcId=$VPC_ID
```

Verifica que los pods están `Running` antes de continuar:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --watch
```

#### 3. Crear el Ingress

El Ingress necesita un Service de tipo `ClusterIP` como backend — el ALB se encarga de la parte pública y enruta el tráfico directamente a los pods:

```bash
kubectl expose deployment nginx --port=80 --type=ClusterIP
```

El manifiesto ya está en `manifests/ingress.yaml`. Aplícalo:

```bash
kubectl apply -f manifests/ingress.yaml
# Espera hasta que ADDRESS tenga valor (~2 min)
kubectl get ingress nginx --watch
```

Verifica el estado del ALB en AWS:

```bash
aws elbv2 describe-load-balancers \
  --region $(terraform output -raw region) \
  --query 'LoadBalancers[].{Name:LoadBalancerName,State:State.Code,DNS:DNSName}' \
  --output table
```

Cuando `State` muestre `active`:

```shell
curl http://ADDRESS
```

#### Limpiar todo lo instalado

> **Importante:** borra el Ingress **antes** de desinstalar el controller. Si desinstalamos primero el controller, el ALB en AWS queda huérfano (sin nadie que lo elimine) y hay que borrarlo manualmente desde la consola.

```bash
# 1. Borrar el Ingress — el controller detecta la eliminación y borra el ALB en AWS
kubectl delete ingress nginx
kubectl delete svc nginx
kubectl delete deployment nginx

# 2. Desinstalar el ALB Controller
helm uninstall aws-load-balancer-controller -n kube-system

# 3. Eliminar la asociación Pod Identity (desvincula el role del ServiceAccount)
ASSOCIATION_ID=$(aws eks list-pod-identity-associations \
  --cluster-name $(terraform output -raw cluster_name) \
  --region $(terraform output -raw region) \
  --namespace kube-system \
  --service-account aws-load-balancer-controller \
  --query "associations[0].associationId" --output text)

aws eks delete-pod-identity-association \
  --cluster-name $(terraform output -raw cluster_name) \
  --region $(terraform output -raw region) \
  --association-id $ASSOCIATION_ID

# 4. Eliminar el IAM role y la política
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws iam detach-role-policy \
  --role-name AWSLoadBalancerControllerRole \
  --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy

aws iam delete-role --role-name AWSLoadBalancerControllerRole
aws iam delete-policy --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy
```

## 5. Headlamp (dashboard web)

Headlamp es el sucesor del Kubernetes Dashboard oficial (archivado en enero de 2026). Se instala en el cluster con Helm y se accede mediante port-forward local, **no** exponiéndolo a internet.

```bash
helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
helm repo update

helm install headlamp headlamp/headlamp --namespace kube-system
```

Verifica que el pod está corriendo:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=headlamp --watch
```

Abre el port-forward (redirige el puerto 80 del Service a tu localhost:8080):

```bash
kubectl port-forward -n kube-system svc/headlamp 8080:80
```

Obtén el token de acceso:

```bash
kubectl create token headlamp --namespace kube-system
```

Accede en `http://localhost:8080` y pega el token para autenticarte.

Para desinstalarlo:

```bash
helm uninstall headlamp -n kube-system
```

## Destrucción

Ya podríamos borrar el cluster:

```bash
terraform destroy
```