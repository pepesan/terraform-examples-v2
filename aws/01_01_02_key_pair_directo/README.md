# Primer ejemplo de Terraform con el proveedor de AWS

## pasos a realizar
- conseguir las credenciales de la cuenta AWS
- Crear clave de acceso
- Esto generará dos datos: Clave de Acceso y Clave de Acceso Secreta
- Copia el fichero .env.example a .env
```shell
cp .env.example .env
```
- recuerda que el fichero .env nunca debe ser público mételo en el .gitignore
- edita el fichero .env para meter las claves en las variables de entorno
- carga el fichero para que se carguen las variables antes de ejecutar cualquier comando terraform
```shell
source .env
```
- con esto ya tendríamos configurado las credenciales del proveedor de AWS

## Con AWS Cli configurado
El fichero .aws/credentials que usa el AWS Cli también sirve para alimentar las credenciales al proveedor de terraform de AWS