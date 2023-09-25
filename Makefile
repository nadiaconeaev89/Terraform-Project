init: 
    terraform init 

validate: init
    terraform validate 

california: validate
    terraform workspace new california || terraform workspace select california && terraform apply -auto-approve  -var-file envs/regions/california.tfvars

zurich: validate
    terraform workspace new zurich || terraform workspace select zurich && terraform apply -auto-approve  -var-file envs/regions/zurich.tfvars

tokyo: validate
    terraform workspace new tokyo || terraform workspace select tokyo && terraform apply -auto-approve  -var-file envs/regions/tokyo.tfvars

build-all: 
    make california && make zurich && make tokyo

#############################################################################################################################################

destroy-california:
    terraform workspace select california &&  terraform destroy -auto-approve -var-file envs/regions/california.tfvars

destroy-zurich:
    terraform workspace select zurich && terraform destroy -auto-approve -var-file envs/regions/zurich.tfvars

destroy-tokyo:
    terraform workspace select tokyo && terraform destroy -auto-approve -var-file envs/regions/tokyo.tfvars

destroy-all:
   make destroy-california && make destroy-zurich && make destroy-tokyo