#!/bin/bash

if [ $(id -u) -ne 0 ]; then
	echo 'Please run this script as root..'
	exit 1
fi

if [ $# -ne 6 ]; then
	echo 'Usage: wordpress.sh <user> <path> <DBname> <DBuser> <DBpass> <DBserver>'
	exit 2
fi

WUSER=$1
WPATH=$2
DBNAME=$3
DBUSER=$4
DBPASS=$5
DBSERVER=$6
CONFIG="${WPATH}/wp-config.php"

echo 'Downloading WordPress..'
cd /opt
wget 'http://wordpress.org/latest.tar.gz'
tar -xzf latest.tar.gz

echo 'Filling directory with files..'
rsync -ar /opt/wordpress/ $WPATH
mkdir $WPATH/wp-content/uploads
chown -R ${WUSER}:${WUSER} ${WPATH}/*

echo 'Configuring WordPress..'
cp ${WPATH}/wp-config-sample.php $CONFIG
sed -i "s/database_name_here/${DBNAME}/" $CONFIG
sed -i "s/username_here/${DBUSER}/" $CONFIG
sed -i "s/password_here/${DBPASS}/" $CONFIG
sed -i "/localhost/${DBSERVER}/" $CONFIG

echo 'WordPress installation success.. Trying to restart webserver..'
systemctl restart httpd > /dev/null 2>&1
systemctl restart nginx > /dev/null 2>&1
service httpd restart > /dev/null 2>&1
service nginx restart > /dev/null 2>&1

echo 'Further installation please access the WEB GUI..'

