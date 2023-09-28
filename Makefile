build-california: 
	terraform init	&& 	terraform workspace new california ||	terraform workspace select california	&&	terraform apply -auto-approve  -var-file envs/regions/california/california.tfvars

build-zurich:
	terraform init	&& 	terraform workspace new zurich ||	terraform workspace select zurich	&&	terraform apply -auto-approve  -var-file envs/regions/zurich/zurich.tfvars

build-tokyo:
	terraform init	&& 	terraform workspace new tokyo ||	terraform workspace select tokyo	&&	terraform apply -auto-approve  -var-file envs/regions/tokyo/tokyo.tfvars

build-all: 
	make california && make zurich && make tokyo

#########################################################################################################################################################################

destroy-california:
	terraform workspace select california &&  terraform destroy -auto-approve -var-file envs/regions/california/california.tfvars

destroy-zurich:
	terraform workspace select zurich && terraform destroy -auto-approve -var-file envs/regions/zurich/zurich.tfvars

destroy-tokyo:
	terraform workspace select tokyo && terraform destroy -auto-approve -var-file envs/regions/tokyo/tokyo.tfvars

destroy-all:
	make destroy-california && make destroy-zurich && make destroy-tokyo