To do:
  Create basic infrastructure on azure through terraform

pre-requisites:
-terraform
-ansible

Steps:
1- Clone the repository
2- Update terraform.tfvars file in terraform folder with the requisites
3- Edit create.sh to write the output to the ansible host file by editing the path
4- Make sure there is only one main.tf file in terraform folder as all create similar resources with same names through different approaches.
5- run the create.sh script from inside the terraform folder

A successful run would write the output to the ansible host file, from where it can be taken further for remote configuration management through ansible.

