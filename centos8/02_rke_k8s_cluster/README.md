# RKE Kubernetes Cluster Installation
Instalation scripts for RKE cluster at centos 8
## .env file
Copy the .env.example file to .env
cp .env.example .env
* Modify .env to adapt to your needs
  * CONTAINER_NAME actually for centos8 to check lxc instance
  * USERNAME: name for the user to log vía ssh to centos node machine
  * SSH_KEY_PATH: path for the $USERNAME ssh key to log into nodes
## Installation Procedure

* On nodes: upload .env files and scripts
* On nodes: ./update_centos8_ssh.sh // update lo lastest version of packages 
* On nodes: reboot machines 
* On Nodes: ./install_docker_centos8.sh // install docker and create user for docker
* On Local: ./create_ssh_key.sh // create ssh kwy for $USERNAME
* Modify .env file to include SSH_IPS to node ips
* On Local: ./upload_ssh_keys.sh // upload $SSH_KEY_PATH to nodes
* On Nodes: Check /home/user/.ssh/authorized_keys
* On Local: Check ssh to nodes with ssh key
* On Local: ssh-add $SSH_KEY_PATH // add key to ssh agent
* On Local: Copy cluster-example.yml to cluster.yml
* On Local: Modify cluster.yml file to include the node ips
* On Local: rke up --ssh-agent-auth // create the rke k8s cluster in nodes 
* On Nodes: ./post_install_docker_centos8.sh
#Open Ports in the nodes
[RKE Port Documentation](https://rancher.com/docs/rke/latest/en/os/#ports)


