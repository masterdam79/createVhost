#!/bin/bash

# Check if parameters are given
if [[ -z "$2" ]];
then
#       echo -e "\e[1;31m[red]\e[0m"
        echo -e "\e[1;31mUsage: ./createAlias.sh <domainname.tld> <domainalias.tld> [www]\e[0m"
        exit
fi

# Some variables
domain=$1
domainAlias=$2
wwwAlias=$3
aliasCount=`grep -n ServerAlias /etc/apache2/sites-available/${domain}.conf | wc -l`

# Check if given domain exists
if [[ ! -f /etc/apache2/sites-available/${domain}.conf ]];
then
        echo -e "\e[1;31mSite: ${domain} not available\e[0m"
        exit
fi

# Check where to insert Alias
if [ ${aliasCount} -gt 0 ];
then
        echo -e "\e[1;32m${aliasCount} x ServerAlias present\e[0m"
        lineServerAlias=`grep -n "ServerAlias" /etc/apache2/sites-available/${domain}.conf | 
tail -1 | awk -F":" '{print $1}'`
        echo -e "\e[1;33mWill insert ServerAlias on line $((lineServerAlias+1))\e[0m"
else
        echo -e "\e[1;32mNo ServerAlias present\e[0m"
        lineServerAlias=`grep -n "ServerName ${domain}" 
/etc/apache2/sites-available/${domain}.conf | awk -F":" '{print $1}'`
        echo -e "\e[1;33mWill insert ServerAlias on line $((lineServerAlias+1))\e[0m"
fi

# Insert the Alias
if [[ -z "$3" ]];
then
        sed -i "$((lineServerAlias+1))iServerAlias $2" 
/etc/apache2/sites-available/${domain}.conf
        sed -i "s/ServerAlias $2/\tServerAlias $2/g" /etc/apache2/sites-available/${domain}.conf
else
        echo -e "\e[1;33mAlso adding www.$2 domain alias\e[0m"
        sed -i "$((lineServerAlias+1))iServerAlias $2" 
/etc/apache2/sites-available/${domain}.conf
        sed -i "s/ServerAlias $2/\tServerAlias $2/g" /etc/apache2/sites-available/${domain}.conf
        sed -i "$((lineServerAlias+2))iServerAlias www.$2" 
/etc/apache2/sites-available/${domain}.conf
        sed -i "s/ServerAlias www.$2/\tServerAlias www.$2/g" 
/etc/apache2/sites-available/${domain}.conf
fi




service apache2 restart

