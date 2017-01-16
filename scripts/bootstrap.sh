#!/usr/bin/env bash

VMNAME=$1
HOSTNAME=$2
DBNAME=$3
DBUSER=$4
DBPASSWD=$5

apt-get install -y software-properties-common
apt-get install -y python-software-properties

apt-get update
apt-get upgrade

apt-get install -y dkms curl build-essential netbase wget git
apt-get install -y virtualbox-guest-x11

echo "mysql-server mysql-server/root_password password $DBPASSWD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DBPASSWD" | debconf-set-selections
apt-get -y install mysql-server

mysql -uroot -p$DBPASSWD -e "CREATE DATABASE $DBNAME"
mysql -uroot -p$DBPASSWD -e "grant all privileges on $DBNAME.* to '$DBUSER'@'localhost' identified by '$DBPASSWD'"

sed -i -e 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
mysql -uroot -p$DBPASSWD -e "grant all privileges on $DBNAME.* to '$DBUSER'@'%' identified by '$DBPASSWD'"

echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | debconf-set-selections

apt-get install -y phpmyadmin
apt-get install -y php-gettext php5-mcrypt php5-curl

sed -i "s/User .*/User vagrant/" /etc/apache2/apache2.conf
sed -i "s/Group .*/Group vagrant/" /etc/apache2/apache2.conf
sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/apache2/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/apache2/php.ini
sed -i "s/max_upload_size = .*/max_upload_size = 512M/" /etc/php5/apache2/php.ini

if ! [ -L /var/www ]; then
  rm -rf /var/www
  ln -fs /vagrant/www /var/www
fi

cat > /etc/apache2/sites-available/$VMNAME.conf <<EOF
<VirtualHost *:80>
    DocumentRoot /var/www/public
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    ServerName $HOSTNAME
</VirtualHost>
EOF

a2ensite $VMNAME
a2enmod rewrite
a2enmod headers

service apache2 restart

su -c "/vagrant/scripts/postinstall.sh" -s /bin/bash vagrant

mv /home/vagrant/composer.phar /usr/bin/composer

ifconfig