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

#creating a machine template so the autoscaling knows what type of machine to work with.

resource "google_compute_instance_template" "compute-engine" {
  depends_on = [
    google_sql_database_instance.database,

  ]
  name                    = var.template_name
  machine_type            = var.machine_type
  can_ip_forward          = false
  project                 = var.project_name
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

}
#creating a target pool

resource "google_compute_target_pool" "team3-project" {
  name    = var.targetpool_name
  project = var.project_name
  region  = var.region
}

#creating a group manager for the instances.
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

#indicating the image for the instance.

data "google_compute_image" "centos" {
  family  = "centos-7"
  project = "centos-cloud"
}