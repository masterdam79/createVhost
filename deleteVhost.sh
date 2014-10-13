#!/bin/bash

if [[ -z "$1" ]];
then
#	echo -e "\e[1;31m[red]\e[0m"
	echo -e "\e[1;31mUsage: ./createVhost.sh <domainname.tld>\e[0m"
	exit
fi

domainuser=$1
password=`tr -dc A-Za-z0-9_ < /dev/urandom | head -c8`
APACHE_LOG_DIR=`grep APACHE_LOG_DIR /etc/apache2/envvars | awk -F'[ $=]' '{ print $3}'`
path=`pwd`
file=`echo $0`
prepath=`echo ${file} | awk -F '/' '{print $1}'`
execpath="${path}/${prepath}/"


# Add user and give home
if id -u ${domainuser//./} >/dev/null 2>&1;
then
	echo -e "\e[1;32mDeleting user ${domainuser//./}\e[0m"
	userdel ${domainuser//./}
else
        echo -e "\e[1;33mUser ${domainuser//./} doesn't exists\e[0m"
fi

# Delete home for user
if [ ! -d /srv/${domainuser//./}/www/${domainuser}/public_html ];
then
	echo -e "\e[1;33mPath /srv/${domainuser//./}/www/${domainuser}/public_html doesn't exists\e[0m"
else
        echo -e "\e[1;32mDeleting home for ${domainuser}\e[0m"
	rm -Rf /srv/${domainuser//./}
fi

# Delete virtual host
if [ ! -f /etc/apache2/sites-available/${domainuser}.conf ];
then
	echo -e "\e[1;33mFile /etc/apache2/sites-available/${domainuser}.conf doesn't exists\e[0m"
else
	echo -e "\e[1;32mDeleting vhost config for ${domainuser}\e[0m"
	rm -fv /etc/apache2/sites-{enabled,available}/${domainuser}.conf
fi

# Delete pool file
if [ ! -f /etc/php5/fpm/pool.d/${domainuser}.conf ];
then
	echo -e "\e[1;33mFile /etc/php5/fpm/pool.d/${domainuser}.conf doesn't exists\e[0m"
else
	echo -e "\e[1;32mDeleting php-fpm config for ${domainuser}\e[0m"
	rm -fv /etc/php5/fpm/pool.d/${domainuser}.conf
fi

echo -e "\e[1;34mDeleting database and database user\e[0m"
${execpath}deleteDatabase.sh ${domainuser}
echo ""
echo -e "\e[1;33mDon't forget to restart apache2 & php-fpm!\e[0m"
echo ""
