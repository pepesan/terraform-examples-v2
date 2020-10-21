# RKE Kubernetes Cluster Installation
Instalation scripts for RKE cluster at centos 8
## .env file
Copy the .env.example file to .env
cp .env.example .env
* Modify .env to adapt to your needs
  * USERNAME: name for the user to log vía ssh to centos node machine
  * ROOT_SSH_KEY_PATH: path for the root ssh key to log into nodes
  * SSH_KEY_PATH: path for the $USERNAME ssh key to log into nodes
## Installation Procedure
* On nodes: upload .env files and scripts, ensure execution permissions to scripts
* On nodes: ./update_centos8_ssh.sh // update lo lastest version of packages 
* On nodes: reboot machines 
* On nodes: ./install_docker_centos8.sh // install docker and create user for docker
* On Nodes: ./post_install_docker_centos8.sh // check swappoff and loaded modules, if modules missing load them
* On Nodes: ./open_rke_posts_centos8.sh // to open k8s ports on each node
* On local: ./create_ssh_key.sh // create ssh key for $USERNAME to log in nodes
* On local: Modify .env file to include SSH_IPS to node ips
* On Local: ./upload_ssh_keys.sh // upload $SSH_KEY_PATH to nodes
* On Nodes: Check /home/$USERNAME/.ssh/authorized_keys
* On Local: Check ssh access of $USERNAME to nodes with ssh key
* On Local: ssh-add $SSH_KEY_PATH // add key to ssh agent
* On Nodes: ./load_kernel_modules.sh // assure loading kernel modules 
* On Local: Copy cluster-example.yml to cluster.yml
* On Local: Modify cluster.yml file to include the node public and private ips
* On Local: rke up --ssh-agent-auth // create the rke k8s cluster in nodes 

#Open Ports in the nodes
[RKE Port Documentation](https://rancher.com/docs/rke/latest/en/os/#ports)


