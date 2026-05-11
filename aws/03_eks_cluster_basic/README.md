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

### Helm (necesario para instalar el ALB Controller)

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh
helm version
```

## 1. Configurar kubectl

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

### Opción A — LoadBalancer (NLB automático)

AWS provisiona un Network Load Balancer en las subnets públicas y devuelve un DNS accesible desde internet:

```bash
# Crear el servicio de tipo LoadBalancer
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Esperar hasta que EXTERNAL-IP tenga valor (puede tardar ~2 min)
kubectl get svc nginx --watch
```

Revisa si funciona correctamente:
```shell
curl http://EXTERNAL-IP
```

#### Borra el servicio

```shell
kubectl delete svc nginx
```
Puede tardar varios minutos en quitar el servicio...

### Opción B — Ingress con ALB Controller (recomendado)

#### 1. Crear el IAM role para el ALB Controller

El ALB Controller necesita permisos AWS para crear Load Balancers. Se usa **EKS Pod Identity** (el addon ya está instalado en el cluster) para inyectar las credenciales automáticamente en los pods.

```bash
# Crear la política en AWS (el fichero ya está en iam/iam_policy.json)
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam/iam_policy.json

# Crear el IAM role (el fichero ya está en iam/trust-policy.json)
aws iam create-role \
  --role-name AWSLoadBalancerControllerRole \
  --assume-role-policy-document file://iam/trust-policy.json

# Adjuntar la política al role
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws iam attach-role-policy \
  --role-name AWSLoadBalancerControllerRole \
  --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy

# Vincular el role al ServiceAccount del controller via Pod Identity
aws eks create-pod-identity-association \
  --cluster-name $(terraform output -raw cluster_name) \
  --region $(terraform output -raw region) \
  --namespace kube-system \
  --service-account aws-load-balancer-controller \
  --role-arn arn:aws:iam::${ACCOUNT_ID}:role/AWSLoadBalancerControllerRole
```

#### 2. Instalar el ALB Controller

Las subnets ya están tagueadas correctamente para su autodescubrimiento.

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update

VPC_ID=$(aws eks describe-cluster \
  --name $(terraform output -raw cluster_name) \
  --region $(terraform output -raw region) \
  --query "cluster.resourcesVpcConfig.vpcId" \
  --output text)

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$(terraform output -raw cluster_name) \
  --set serviceAccount.create=true \
  --set region=$(terraform output -raw region) \
  --set vpcId=$VPC_ID
```

Verifica que los pods están `Running`:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --watch
```

#### 3. Crear el Ingress

El Ingress necesita un Service de tipo `ClusterIP` como backend. El ALB se encarga de la parte pública:

```bash
kubectl expose deployment nginx --port=80 --type=ClusterIP
```

Una vez el controller está `Running`, crea el fichero `ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip  # enruta directo al pod, compatible con ClusterIP
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx
                port:
                  number: 80
```

```bash
kubectl apply -f manifests/ingress.yaml
kubectl get ingress nginx --watch # espera hasta que ADDRESS tenga valor (~2 min)
```

Comprueba el  LB:
```shell
aws elbv2 describe-load-balancers \
    --region $(terraform output -raw region) \
    --query "LoadBalancers[?contains(DNSName, 'k8s-default-nginx')].[LoadBalancerName,State.Code,DNSName]" \
    --output table
```
Ahora con el LB en funcionamiento podemos hacer la consulta

```shell
curl http://ADDRESS
```

#### Limpiar todo lo instalado

> **Importante:** borra el Ingress **antes** de desinstalar el controller. Si desinstalamos primero el controller, el LB en AWS queda huérfano y hay que borrarlo manualmente.

```bash
# Borrar primero el Ingress para que el controller elimine el LB en AWS
kubectl delete ingress nginx
kubectl delete svc nginx
kubectl delete deployment nginx

# Desinstalar el ALB Controller
helm uninstall aws-load-balancer-controller -n kube-system

# Eliminar la asociación Pod Identity
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

# Eliminar el IAM role y la política
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws iam detach-role-policy \
  --role-name AWSLoadBalancerControllerRole \
  --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy

aws iam delete-role --role-name AWSLoadBalancerControllerRole
aws iam delete-policy --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy
```

## 5. Headlamp (dashboard web)

Headlamp es el sucesor del Kubernetes Dashboard oficial (archivado en 2026). Se instala en el cluster con Helm y se accede mediante port-forward local, **no** exponiéndolo a internet.

```bash
helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
helm repo update

helm install headlamp headlamp/headlamp --namespace kube-system
```

Verifica que el pod está corriendo:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=headlamp
```

Abre el port-forward:

```bash
kubectl --namespace kube-system port-forward \
  $(kubectl get pods --namespace kube-system -l "app.kubernetes.io/name=headlamp,app.kubernetes.io/instance=headlamp" -o jsonpath="{.items[0].metadata.name}") \
  8080:4466
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