# Ejemplo de uso de Ansible con DO
## Instalación de Terraform
### Comandos Manuales para Ubuntu 20.04
<code>
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
<br/>
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
<br/>
sudo apt-get update && sudo apt-get install terraform
<br/>
</code>
### Comando para Ansible
ansible-playbook -i inventory tasks/install_terraform_local.yaml -b --ask-become-pass
# Uso en Terraform
<code>terraform init
<br/>
</code>
<code>
terraform validate
<br/>
</code>
<code>
terraform apply
<br/>
</code>
<code>
terraform destroy
<br/>
</code>
# Conexión SSH de prueba
ssh -i /home/pepesan/.ssh/id_rsa -l root IP_SERVER
# Configuración del agente ssh
ssh-agent bash
ssh-add ~/.ssh/id_rsa
# Lanzamiento de Ansible al servidor remoto
ansible-playbook tasks/install_remote.yaml
