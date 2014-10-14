#!/bin/bash


# Update system
apt-get update && apt-get upgrade


# Install packages
apt-get -y install git apache2 mysql-server php5-mysql php5 libapache2-mod-php5 php5-mcrypt php5-fpm


# Enable mods

a2enmod proxy_fcgi



# MySQL secure (interactive)
mysql_install_db

mysql_secure_installation


# Ask for MySQL root password to put it in /etc/mysql.passwd
while true; do
	read -p "Enter MySQL root password" password
	if [ ${password} == "" ];
	then
		exit;
	else
		echo ${password} > /etc/mysql.passwd
		chmod 400 /etc/mysql.passwd
	fi
done
