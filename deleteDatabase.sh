#!/bin/bash

if [[ -z "$1" ]];
then
#	echo -e "\e[1;31m[red]\e[0m"
	echo -e "\e[1;31mUsage: ./deleteDatabase.sh <domainname.tld>\e[0m"
	exit
fi

if [ ! -f /etc/mysql.passwd ];
then
	echo -e "\e[1;31mMake sure your MySQL root password is in /etc/mysql.passwd (chmod 400)\e[0m"
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

dbCheck=`mysql -u${mysqlAdminUser} -p${mySqlPwFileContent} -e "SHOW DATABASES" | grep ${mySqlUser} | wc -l`
dbUserCheck=`mysql -u${mysqlAdminUser} -p${mySqlPwFileContent} -e "SELECT user FROM mysql.user" | grep ${mySqlUser} | wc -l`

# Check if database already exists, else create database
if [ "${dbCheck}" -gt 0 ];
then
	echo -e "\e[1;32mDeleting database ${mySqlUser}\e[0m"
	mysql -u${mysqlAdminUser} -p${mySqlPwFileContent} -e "DROP DATABASE ${mySqlUser};"
else
	echo -e "\e[1;33mDatabase ${mySqlUser} doesn't exists\e[0m"
fi

# Check is user already exists, else create user ant grant privileges
if [ "${dbUserCheck}" -gt 0 ];
then
	echo -e "\e[1;32mDropping user ${mySqlUser} for localhost\e[0m"
	mysql -u${mysqlAdminUser} -p${mySqlPwFileContent} -e "DROP USER ${mySqlUser}@'localhost';"
	echo -e "\e[1;32mDropping user ${mySqlUser} for all hosts\e[0m"
	mysql -u${mysqlAdminUser} -p${mySqlPwFileContent} -e "DROP USER ${mySqlUser}@'%';"
else
	echo -e "\e[1;33mUser ${mySqlUser} doesn't exists..\e[0m"
fi

mysql -u${mysqlAdminUser} -p${mySqlPwFileContent} -e "FLUSH PRIVILEGES"

