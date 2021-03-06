#!/bin/bash
#Author: Perry

if [ $(id -u) -ne 0 ]; then
        echo "Please run this script with root privileges.."
        exit 2
fi

[ -f /etc/os-release ] && grep centos /etc/os-release > /dev/null && DIST='centos' || DIST='ubuntu'

if [ $DIST = "centos" ]; then
	yum install -y epel-release > /tmp/yum.epel.log 2>&1
	rpm -q nginx > /dev/null && echo 'NGINX already installed' || yum install nginx -y > /tmp/yum.nginx.log 2>&1
else
	apt list --installed | grep nginx > /dev/null && echo 'NGINX already isntalled' || apt-get update > /dev/null && apt-get install -y nginx > /tmp/apt.nginx.log 2>&1
fi

#Check if systemd
type systemctl > /dev/null

if [ $? -eq 0 ]; then
	systemctl enable nginx && systemctl start nginx
else
	service nginx restart > /dev/null
	chkconfig nginx on > /dev/null 2>&1
fi


#Open port 80
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
