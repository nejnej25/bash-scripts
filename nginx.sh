#!/bin/bash
#Author: Perry

if [ $(id -u) -ne 0 ]; then
        echo "Please run this script with root privileges.."
        exit 2
fi

[ -f /etc/os-release ] && grep 'ID="centos"' /etc/os-release > /dev/null && DIST='centos' || DIST='rhel'
[ -f /etc/os-release ] && releasever=$(cat /etc/os-release | grep VERSION_ID| cut -f 2 -d=) || releasever='6'

echo 'Adding NGINX repository..'
cat > /etc/yum.repos.d/nginx.repo<<EOF
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/$DIST/$releasever/\$basearch/
gpgcheck=0
enabled=1
EOF

rpm -q nginx > /dev/null  && echo 'NGINX already installed' || yum install nginx -y > /tmp/yum.nginx.log 2>&1
systemctl enable nginx > /dev/null && systemctl start nginx
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
rpm -q iptables-services > /dev/null && service iptables save || echo 'IPTables service not installed, save it yourself!'
