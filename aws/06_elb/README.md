## Ejemplo de ALB 

## Instalación de Grpahviz
```shell
sudo apt update
sudo apt install -y graphviz
```
## Vista de Grafo
```shell
terraform graph > grafo.dot
dot -Tpng grafo.dot -o grafo.png
```
Genera un grafo.dot con los datos del grafo y luego genera un png con los datos del grafo.dot