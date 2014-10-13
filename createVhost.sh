#!/bin/bash

if [[ -z "$1" ]];
then
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


echo -e "\e[1;34mWriting FTP login creds to /srv/${domainuser//./}/ftp.cred\e[0m"
echo "FTP User: ${domainuser//./}" > /srv/${domainuser//./}/ftp.cred
echo "FTP Password: ${password}" >> /srv/${domainuser//./}/ftp.cred

# Restrict access to file
chown ${domainuser//./}. /srv/${domainuser//./}/ftp.cred
chmod 600 /srv/${domainuser//./}/ftp.cred

# Add user and give home
if id -u ${domainuser//./} >/dev/null 2>&1;
then
        echo -e "\e[1;33mUser ${domainuser//./} already exists\e[0m"
else
	echo -e "\e[1;32mCreating user ${domainuser//./} with password ${password}\e[0m"
	useradd -m -p ${password} --base-dir /srv ${domainuser//./}
	printf "${password}\n${password}\n" | passwd ${domainuser//./}
fi

# Change user's shell
echo -e "\e[1;32mChanging the shell to /bin/bash for user ${domainuser//./}\e[0m"
chsh -s /bin/bash ${domainuser//./}

# Create home for user
if [ ! -d /srv/${domainuser//./}/www/${domainuser}/public_html ];
then
        echo -e "\e[1;32mCreating home for ${domainuser}\e[0m"
	mkdir -pv /srv/${domainuser//./}/www/${domainuser}/public_html
else
	echo -e "\e[1;33mPath /srv/${domainuser//./}/www/${domainuser}/public_html already exists\e[0m"
fi

# Add welcome page to its home
if [ ! -f /srv/${domainuser//./}/www/${domainuser}/public_html/index.html ];
then
        echo -e "\e[1;32mCreating welcome page for ${domainuser//./} in /srv/${domainuser//./}/www/${domainuser}/public_html/index.html\e[0m"
	mkdir -pv /srv/${domainuser//./}/www/${domainuser}/public_html
	cat << EOF > /srv/${domainuser//./}/www/${domainuser}/public_html/index.html
	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
	<html>
		<head>
			<title>Welcome ${domainuser//./}!</title>
		</head>
		<body>
			<h1>Welcome to ${domainuser}</h1>
		</body>
	</html>
EOF
else
        echo -e "\e[1;33mFile /srv/${domainuser//./}/www/${domainuser}/public_html/index.html already exists\e[0m"
fi

# Make suer the user can live in it's home
echo -e "\e[1;32mChanging ownership of files in /srv/${domainuser//./} to ${domainuser//./}:${domainuser//./}\e[0m"
chown -Rv ${domainuser//./}:${domainuser//./} /srv/${domainuser//./}

# Get the last userd PHP-FPM port in a var
lastPort=`egrep -r "^listen = 127.0.0.1" /etc/php5/fpm/pool.d/ | awk -F':' '{print $3}' | sort | tail -1`;

# Create virtual host
if [ ! -f /etc/apache2/sites-available/${domainuser}.conf ];
then
	echo -e "\e[1;32mChanging vhost config for ${domainuser}\e[0m"
	mkdir -pv ${APACHE_LOG_DIR}/domains
	cat << EOF > /etc/apache2/sites-available/${domainuser}.conf
<VirtualHost *:8080>
	ServerName ${domainuser}
	
	ServerAdmin beheer@${domainuser}
	DocumentRoot /srv/${domainuser//./}/www/${domainuser}/public_html
	
	ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:$((lastPort+1))/srv/${domainuser//./}/www/${domainuser}/public_html/$1
	
	<Directory /srv/${domainuser//./}/www/${domainuser}/public_html>
		Require all granted
	</Directory>
	
	ErrorLog ${APACHE_LOG_DIR}/domains/${domainuser}-error.log
	CustomLog ${APACHE_LOG_DIR}/domains/${domainuser}-access.log combined
</VirtualHost>
EOF
else
	echo -e "\e[1;33mFile /etc/apache2/sites-available/${domainuser}.conf already exists\e[0m"
fi

# Create Pool
if [ ! -f /etc/php5/fpm/pool.d/${domainuser}.conf ];
then
	cat << EOF > /etc/php5/fpm/pool.d/${domainuser}.conf
[${domainuser}]
user = ${domainuser//./}
group = ${domainuser//./}
listen = 127.0.0.1:$((lastPort+1))
listen.owner = ${domainuser//./}
listen.group = ${domainuser//./}
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
chdir = /
EOF
else
	echo -e "\e[1;33mFile /etc/php5/fpm/pool.d/${domainuser}.conf already exists\e[0m"
fi

if [ ! -h /etc/apache2/sites-enabled/${domainuser}.conf ];
then
	echo -e "\e[1;32mEnabling site ${domainuser}\e[0m"
	a2ensite ${domainuser}.conf
else
        echo -e "\e[1;33mFile /etc/apache2/sites-enabled/${domainuser}.conf already exists\e[0m"
fi

echo -e "\e[1;34mCreating alias\e[0m"
${execpath}createAlias.sh ${domainuser} www.${domainuser}
echo -e "\e[1;34mCreating database and database user\e[0m"
${execpath}createDatabase.sh ${domainuser}

echo ""
echo -e "\e[1;33mDon't forget to restart apache2!\e[0m"
echo ""

