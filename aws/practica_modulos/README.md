# Práctica de definición de módulos y uso de módulos en Terraform

## Objetivo
En base al ejemplo 01_02_simple_vps, crear un módulo que permita crear una máquina virtual en AWS EC2 con los siguientes parámetros:
- Nombre de la máquina virtual
- Tipo de instancia
- Clave SSH para acceder a la máquina virtual
- Región donde se desplegará la máquina virtual
## Datos de salida
- ID de la máquina virtual creada
- Dirección IP pública de la máquina virtual
- Comando ssh para acceder a la máquina virtual

## Módulo principal
Crea un módulo principal que utilice el módulo creado anteriormente para desplegar una máquina virtual con los siguientes parámetros:
- Nombre de la máquina virtual: "mi-vps-alumnoxx"
- Tipo de instancia: "t3.micro"
- Clave SSH basada en fichero de tu clave pública
- Región: "eu-west-3"

## Salida del módulo principal
- ID de la máquina virtual creada
- Dirección IP pública de la máquina virtual
- Comando ssh para acceder a la máquina virtual

## Buenas prácticas
- Utiliza variables para parametrizar el módulo y el módulo principal.
- Utiliza outputs para mostrar los datos de salida.
- Organiza el código en archivos separados para el módulo y el módulo principal.
- Usa los ficheros main.tf, variables.tf y outputs.tf para organizar el código de manera clara y estructurada.

## Pruebas
- Despliega la máquina virtual utilizando el módulo principal y verifica que se ha creado correctamente en AWS EC2.
- Verifica que los datos de salida son correctos y que puedes acceder a la máquina virtual
- Destruye la máquina virtual utilizando Terraform para limpiar los recursos creados.