# Conexión a la BBDD

## Descargar el certificado de Amazon RDS
curl -o global-bundle.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
## Conexión a la BBDD
mysql -h rds.endpoint -P 3306 -u admin -p --ssl-ca=./global-bundle.pem

## Nos pedirá la contraseña, la introducimos y ya estaremos conectados a la base de datos.