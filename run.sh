#!/bin/bash

echo "Exporting ENV Varibales"

source ./.env

echo "Ansible Playbook executaion for Validator"

ansible-playbook playbooks/ec2-validator.yml  \
--connection=local  \
--extra-var=" \
	aws_region=$aws_region \
	aws_keypair=$aws_keypair \
	aws_sg_id=$aws_sg_id \
	aws_instance_type=$aws_instance_type \
	aws_ami_id=$aws_ami_id \
	aws_instance_count_validator=$aws_instance_count_validator \
	aws_instance_tag_validator=$aws_instance_tag_validator \
	aws_subnet_id=$aws_subnet_id \
	aws_access_key=$aws_access_key \
	aws_secret_key=$aws_secret_key \
	aws_ebs_size=$aws_ebs_size \
	aws_ebs_type=$aws_ebs_type \
" \
--tags=ec2-create \
-e "ansible_python_interpreter=$python_path"  | grep -i msg | awk '{print$2}' | cut -d '"' -f 2  | sed s/$/:/ > validator_ips

awk '/ec2-validator-ips/{printf $2 ""; while(getline line<"validator_ips"){print "       " line};next};1' add_ip.yml > tmp.yml

echo "Ansible Playbook executaion for Sentry"

ansible-playbook playbooks/ec2-sentry.yml  \
--connection=local  \
--extra-var=" \
	aws_region=$aws_region \
	aws_keypair=$aws_keypair \
	aws_sg_id=$aws_sg_id \
	aws_instance_type=$aws_instance_type \
	aws_ami_id=$aws_ami_id \
	aws_instance_count_sentry=$aws_instance_count_sentry \
	aws_instance_tag_sentry=$aws_instance_tag_sentry \
	aws_subnet_id=$aws_subnet_id \
	aws_access_key=$aws_access_key \
	aws_secret_key=$aws_secret_key \
	aws_ebs_size=$aws_ebs_size \
	aws_ebs_type=$aws_ebs_type \
" \
--tags=ec2-create \
-e "ansible_python_interpreter=$python_path" | grep -i msg | awk '{print$2":"}' | cut -d '"' -f 2 | sed s/$/:/ > sentry_ips

awk '/ec2-sentry-ips/{printf $2 ""; while(getline line<"sentry_ips"){print "       " line};next};1' tmp.yml >  inventory.yml

## Ping Validator
if [[ $aws_instance_count_sentry == 0 ]]; then
	echo "Checking Validator Connectivity"
	ansible validator -m ping

else
	
	echo "Checking Sentry Connectivity"
	ansible sentry -m ping
	echo "Checking Validator Connectivity"
	ansible validator -m ping
fi

sleep 120

# Anible Playbook Executation on Validator & Sentry
if [[ $aws_instance_count_sentry == 0 ]]; then
   	echo "Ansible Playbook executaion for Validator without Sentry"
    ansible-playbook -l validator playbooks/network.yml --extra-var="bor_branch=v0.2.14 heimdall_branch=v0.2.9-bone network_version=alpha-v3 network_launch_branch=alpha_v3 node_type=without-sentry heimdall_network=local"


else
    echo "Ansible Playbook executaion for Validator with Sentry"
    ansible-playbook -l validator playbooks/network.yml --extra-var="bor_branch=v0.2.14 heimdall_branch=v0.2.9-bone network_version=alpha_v3 network_launch_branch=alpha_v3 node_type=sentry/validator heimdall_network=local"

	echo "Ansible Playbook executaion for Sentry"
    ansible-playbook -l sentry playbooks/network.yml --extra-var="bor_branch=v0.2.14 heimdall_branch=v0.2.9-bone network_version=alpha-v3 network_launch_branch=alpha_v3 node_type=sentry/sentry heimdall_network=local"
fi

