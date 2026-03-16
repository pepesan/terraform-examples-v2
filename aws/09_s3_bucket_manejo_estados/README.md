# Guía

## Después de destruir 

Puede dar un fallo de no poder borrarlo por tener contenido. Para solucionarlo, hay que ir a la consola de AWS, entrar en el bucket y borrar el contenido manualmente. Después, volver a ejecutar `terraform destroy` y ya se borrará el bucket sin problemas.

# Manejo de estados
Ver todos los recursos en el estado
terraform state list
# Ver detalles de un recurso en el estado
terraform state show aws_s3_bucket.b

# Mover un recurso dentro del estado (cambiar nombre)
terraform state mv aws_s3_bucket.b aws_s3_bucket.storage
# Eliminar un recurso del estado
terraform state rm aws_s3_bucket.storage

# Ver el estado completo
terraform show
