#!/bin/bash 

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