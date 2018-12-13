#!/bin/bash
terraform init -input=false
terraform plan -out=tfplan -input=false
terraform apply -input=false tfplan
temp=`terraform output -json web_ips | jq '.value['$count']'`
address=`echo $temp | awk -F \" '{ print $2 }'`
echo -e "$address" > /root/root/nodejs_app_deployment_through_ansible_on_azure/ansible/ansible/hosts
