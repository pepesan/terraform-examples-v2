# Instalación de LocalStack

## Requisitos previos
- Docker
- Docker Compose

## Pasos de instalación
1. Descarga el ejecutable de LocalStack:
   ```bash
   curl --output localstack-cli-4.14.0-linux-amd64-onefile.tar.gz \
    --location https://github.com/localstack/localstack-cli/releases/download/v4.14.0/localstack-cli-4.14.0-linux-amd64-onefile.tar.gz
    ```
2. Extrae el archivo descargado:
    ```bash
    sudo tar xvzf localstack-cli-4.14.0-linux-*-onefile.tar.gz -C /usr/local/bin
    ```
3. Verifica la instalación ejecutando el siguiente comando:
    ```bash
    localstack --version
    ```
4. Crea una cuenta en LocalStack: https://app.localstack.cloud/
Esto te permitirá obtener un token de autenticación necesario para utilizar los servicios de LocalStack.
5. Configura el token de LocalStack en tu entorno:
    ```bash
    localstack auth set-token XXXXX
    ```
6. Arranca LocalStack utilizando el siguiente comando:
    ```bash
    localstack start -d
    ```
7. Instala la AWS CLI para interactuar con los servicios de AWS simulados por LocalStack:
    ```bash
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    ```
7. Configura las credenciales de AWS para LocalStack:
    ```bash
    export AWS_ACCESS_KEY_ID="test"
    export AWS_SECRET_ACCESS_KEY="test"
    export AWS_DEFAULT_REGION="us-east-1"
    ```
8. Despliega un bucket de S3 en LocalStack utilizando el siguiente comando:
    ```bash
    aws s3 mb s3://bucket1 --endpoint-url=http://localhost.localstack.cloud:4566
    ```
9. Verifica que el bucket se ha creado correctamente:
    ```bash
   aws s3 ls --endpoint-url=http://localhost.localstack.cloud:4566
    ```
10. Haz permanente la configuración de las credenciales de AWS para LocalStack agregando las siguientes líneas a tu archivo `~/.bashrc` o `~/.zshrc`:
    ```bash
    mkdir -p ~/.aws
    nano ~/.aws/credentials
    ```
    Agrega lo siguiente al archivo:
    ```
    [default]
    aws_access_key_id = test
    aws_secret_access_key = test
    ```
    Crea el fichero de configuración de AWS
    ```bash
    
    nano ~/.aws/config
    ```
    Agrega lo siguiente al archivo:
    ```
    [default]
    region = us-east-1
    output = json
    ```
12. Comprueba que las credenciales se han guardado correctamente:
    ```bash
    aws s3 ls --endpoint-url=http://localhost.localstack.cloud:4566
    ```
11. Para detener LocalStack, utiliza el siguiente comando:
    ```bash
    localstack stop
    ```
12. Para eliminar LocalStack, utiliza el siguiente comando:
    ```bash
    localstack uninstall
    ```
    
   