# Terraform Three-Tier-Application on GCP
This project contains a dynamic terraform code to deploy a three-tier application with Google Cloud resources.

### What you will need to get started
- Google account
- Google billing account
- Google cloud storage bucket (to store a backend)

## Set a Project 
Google Cloud project forms the basis for creating, enabling, and using all Google Cloud services, we will set it up with terraform code. You need to be in the Account directory and run Terraform init and Terraform apply to create a new project.

## Backend setup
We use a Google Cloud Storage bucket (created directly in the console) as a backend to store our state configuration file to allow multiple team members to work on the project together
```
terraform {
  backend "gcs" {
    bucket = "your bucket name"
    prefix = "terraform/state"
  }
}
```

## VPC
We used "google_compute_network" resource to create a global VPC and a subnet for each region automatically across the 10.128.0.0/9 address range.
```
resource "google_compute_network" "vpc-network-team3-project" {
  name                    = var.vpc_name
  auto_create_subnetworks = "true"
  routing_mode            = "GLOBAL"
}
```
## Autoscaling
Managed instance groups (MIGs) offer autoscaling capabilities that let you automatically add or delete VM instances from a MIG according to an autoscaling policy that you define. Autoscaling works by adding more VMs to your MIG when there is more load (scaling out), and deleting VMs when the need for VMs is lowered (scaling in).
```
resource "google_compute_autoscaler" "team3-project" {
  depends_on = [
    google_sql_database_instance.database,

  ]
  name   = var.ASG_name
  zone   = var.zone
  target = google_compute_instance_group_manager.my-igm.self_link

  autoscaling_policy {
    max_replicas    = var.maximum_instances
    min_replicas    = var.minimum_instances
    cooldown_period = 60
  }
}
```


An instance template is a convenient way to save a virtual machine's (VM) configuration that includes machine type, boot disk image, labels, startup script, and other instance properties. If you want to create a group of identical instances–a MIG–you must have an instance template that the group can use.

```
resource "google_compute_instance_template" "compute-engine" {
  depends_on = [
    google_sql_database_instance.database,

  ]
  name                    = var.template_name
  machine_type            = var.machine_type
  can_ip_forward          = false
  project                 = var.project_name
```

 `gcloud compute images list` command pulls up a list of available images. We used a CentOS 7 image.
 ```
data "google_compute_image" "centos" {
  family  = "centos-7"
  project = "centos-cloud"
}
```

```
tags = ["wordpress-firewall"]

  disk {
    source_image = data.google_compute_image.centos.self_link
  }

  network_interface {
    network = google_compute_network.vpc-network-team3-project.id
    access_config {
      // Include this section to give the VM an external ip address
    }
  }
```

Startup script to download and install Wordpress. To check if the script works, enter VM public IP in the browser and it will load a WP page.
```
metadata_startup_script = <<SCRIPT
    sudo yum install httpd wget unzip epel-release mysql -y
    sudo yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
    sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    sudo yum -y install yum-utils
    sudo yum-config-manager --enable remi-php81   [Install PHP 8.1]
    sudo yum -y install php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo
    sudo wget https://wordpress.org/latest.tar.gz
    sudo tar -xf latest.tar.gz -C /var/www/html/
    sudo mv /var/www/html/wordpress/* /var/www/html/
    sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
    sudo chmod 666 /var/www/html/wp-config.php
    sed 's/'database_name_here'/'${google_sql_database.database.name}'/g' /var/www/html/wp-config.php -i
    sed 's/'username_here'/'${google_sql_user.users.name}'/g' /var/www/html/wp-config.php -i
    sed 's/'password_here'/'${var.db_password}'/g' /var/www/html/wp-config.php -i
    sed 's/'localhost'/'${google_sql_database_instance.database.ip_address.0.ip_address}'/g' /var/www/html/wp-config.php -i
    sed 's/SELINUX=permissive/SELINUX=enforcing/g' /etc/sysconfig/selinux -i
    sudo getenforce
    sudo setenforce 0
    sudo chown -R apache:apache /var/www/html/
    sudo systemctl start httpd
    sudo systemctl enable httpd

    SCRIPT
```

External passthrough Network Load Balancers can use either a backend service or a target pool to define the group of backend instances that receive incoming traffic. 
```
resource "google_compute_target_pool" "team3-project" {
  name    = var.targetpool_name
  project = var.project_name
  region  = var.region
}
```
The Google Compute Engine Instance Group Manager API creates and manages pools of homogeneous Compute Engine virtual machine instances from a common instance template.
```
resource "google_compute_instance_group_manager" "my-igm" {
  name    = var.igm_name
  zone    = var.zone
  project = var.project_name
  version {
    instance_template = google_compute_instance_template.compute-engine.self_link
    name              = "primary"
  }
  target_pools       = [google_compute_target_pool.team3-project.self_link]
  base_instance_name = "team3-project"
}
```

## Load Balancing
A load balancer distributes user traffic across multiple instances of your applications. By spreading the load, load balancing reduces the risk that your applications experience performance issues.
```
module "lb" {
  source       = "GoogleCloudPlatform/lb/google"
  version      = "2.2.0"
  region       = var.region
  name         = var.lb_name
  service_port = 80
  target_tags  = ["my-target-pool"]
  network      = google_compute_network.vpc-network-team3-project.name
}
```
## Database
Cloud SQL offers a fully-managed database service for MySQL.
Create a new Google SQL Database Instance:
```
resource "google_sql_database_instance" "database" {
  name                = var.dbinstance_name
  database_version    = var.data_base_version
  region              = var.region
  root_password       = var.db_password
  deletion_protection = "false"
  project             = var.project_name
```
Represents a SQL database inside the Cloud SQL instance, hosted in Google's cloud:
```
resource "google_sql_database" "database" {
  name     = var.db_name
  instance = google_sql_database_instance.database.name
}
```
Creates a new Google SQL User on a Google SQL User Instance:
```
resource "google_sql_user" "users" {
  name     = var.db_username
  instance = google_sql_database_instance.database.name
  host     = var.db_host
  password = var.db_password
}
```
## Build Resources
To deploy all of the above-mentioned resources you need to be in the proper folder inside the google project and run terraform init and terraform apply. After the resources are created, verify it in the Google console and check if the WordPress is loading.
