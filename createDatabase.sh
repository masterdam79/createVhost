#!/bin/bash

if [[ -z "$1" ]];
then
#       echo -e "\e[1;31m[red]\e[0m"
        echo -e "\e[1;31mUsage: ./createDatabase.sh <domainname.tld>\e[0m"
        exit
fi

if [[ -z "$2" ]];
then
        mySqlUserPassword=`tr -dc A-Za-z0-9_ < /dev/urandom | head -c8`
else
        mySqlUserPassword=$2
fi

# Create database
domainuser=$1
mySqlUser=`echo ${domainuser//./} | cut -c1-16`
mySqlUserPassword=`tr -dc A-Za-z0-9_ < /dev/urandom | head -c8`
mysqlAdminUser="root"
mySqlPwFileContent=`cat /etc/mysql.passwd`

echo -e "\e[1;34mWriting MySQL login creds to /srv/${domainuser//./}/mysql.cred\e[0m"
echo "MySQL User: ${domainuser//./}" > /srv/${domainuser//./}/mysql.cred
echo "MySQL Database: ${domainuser//./}" >> /srv/${domainuser//./}/mysql.cred
echo "MySQL Password: ${mySqlUserPassword}" >> /srv/${domainuser//./}/mysql.cred

chmod 750 /srv/${domainuser//./}/mysql.cred

dbCheck=`mysql -u${mysqlAdminUser} -p${mySqlPwFileContent} -e "SHOW DATABASES" | grep cnroodcom 
| wc -l`
dbUserCheck=`mysql -u${mysqlAdminUser} -p${mySqlPwFileContent} -e "SELECT user FROM mysql.user" 
| grep cnroodcom | wc -l`

# Check if database already exists, else create database
if [ "${dbCheck}" -gt 0 ];
then
        echo -e "\e[1;33mDatabase ${mySqlUser} already exists\e[0m"
else
        echo -e "\e[1;32mCreating database ${mySqlUser}\e[0m"
        mysql -u${mysqlAdminUser} -p${mySqlPwFileContent} -e "CREATE DATABASE ${mySqlUser};"
fi

# Check is user already exists, else create user ant grant privileges
if [ "${dbUserCheck}" -gt 0 ];
then
        echo -e "\e[1;33mUser ${mySqlUser} already exists..\e[0m"
else
        echo -e "\e[1;32mCreating user ${mySqlUser} for database ${mySqlUser}\e[0m"
        mysql -u${mysqlAdminUser} -p${mySqlPwFileContent} -e "GRANT USAGE ON *.* TO 
${mySqlUser}@localhost IDENTIFIED BY \"${mySqlUserPassword}\";"
        echo -e "\e[1;32mGranting user ${mySqlUser} all privileges for all tables in database 
${mySqlUser}\e[0m"
        mysql -u${mysqlAdminUser} -p${mySqlPwFileContent} -e "GRANT ALL PRIVILEGES ON 
${mySqlUser}.* TO ${mySqlUser}@localhost;"
fi

mysql -u${mysqlAdminUser} -p${mySqlPwFileContent} -e "FLUSH PRIVILEGES"

