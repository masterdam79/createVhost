#!/bin/bash

if [[ -z "$1" ]];
then
#       echo -e "\e[1;31m[red]\e[0m"
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

# Create home for user
if [ ! -d /srv/${domainuser//./}/www/${domainuser}/public_html ];
then
        echo -e "\e[1;32mCreating home for ${domainuser}\e[0m"
        mkdir -pv /srv/${domainuser//./}/www/${domainuser}/public_html
else
        echo -e "\e[1;33mPath /srv/${domainuser//./}/www/${domainuser}/public_html already 
exists\e[0m"
fi

# Add welcome page to its home
if [ ! -f /srv/${domainuser//./}/www/${domainuser}/public_html/index.html ];
then
        echo -e "\e[1;32mCreating welcome page for  ${domainuser//./}\e[0m"
        mkdir -pv /srv/${domainuser//./}/www/${domainuser}/public_html
        cat << EOF > /srv/${domainuser//./}/www/${domainuser}/public_html/index.html
        <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" 
"http://www.w3.org/TR/html4/loose.dtd">
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
        echo -e "\e[1;33mFile /srv/${domainuser//./}/www/${domainuser}/public_html/index.html 
already exists\e[0m"
fi

# Make suer the user can live in it's home
chown -Rv ${domainuser//./}:${domainuser//./} /srv/${domainuser//./}

# Create virtual host
if [ ! -f /etc/apache2/sites-available/${domainuser}.conf ];
then
        echo -e "\e[1;32mChanging vhost config for ${domainuser}\e[0m"
        cp -pv /etc/apache2/sites-available/000-default.conf 
/etc/apache2/sites-available/${domainuser}.conf
        sed -i 's/webmaster@localhost/beheer@denit.nl/g' 
/etc/apache2/sites-available/${domainuser}.conf
        sed -i "s#/var/www/html#/srv/${domainuser//./}/www/${domainuser}/public_html#g" 
/etc/apache2/sites-available/${domainuser}.conf
        mkdir -pv ${APACHE_LOG_DIR}/domains
        sed -i 's#${APACHE_LOG_DIR}#${APACHE_LOG_DIR}/domains/#g' 
/etc/apache2/sites-available/${domainuser}.conf
        sed -i "s@error.log@${domainuser}-error.log@g" 
/etc/apache2/sites-available/${domainuser}.conf
        sed -i "s@access.log@${domainuser}-access.log@g" 
/etc/apache2/sites-available/${domainuser}.conf
        sed -i "s@#ServerName www.example.com@ServerName ${domainuser}@g" 
/etc/apache2/sites-available/${domainuser}.conf
else
        echo -e "\e[1;33mFile /etc/apache2/sites-available/${domainuser}.conf already 
exists\e[0m"
fi


if [ ! -h /etc/apache2/sites-enabled/${domainuser}.conf ];
then
        echo -e "\e[1;32mEnabling site ${domainuser}\e[0m"
        a2ensite ${domainuser}.conf
else
        echo -e "\e[1;33mFile /etc/apache2/sites-enabled/${domainuser}.conf already exists\e[0m"
fi

echo -e "\e[1;32mRestarting apache2\e[0m"
echo -e "\e[1;34mCreating alias\e[0m"
${execpath}createAlias.sh ${domainuser} www.${domainuser}
echo -e "\e[1;34mCreating database and database user\e[0m"
${execpath}createDatabase.sh ${domainuser}

