# RKE Kubernetes Cluster Installation
Instalation scripts for RKE cluster at centos 8
## .env file
Copy the .env.example file to .env
cp .env.example .env
* Modify .env to adapt to your needs
  * CONTAINER_NAME actually for centos8 to check lxc instance
  * USERNAME: name for the user to log vía ssh to centos node machine
## Installations Script
* install.sh
  * ./install_docker_centos8.sh
  * ./post_install_docker_centos8.sh
#Open Ports in the nodes
[RKE Port Documentation](https://rancher.com/docs/rke/latest/en/os/#ports)


