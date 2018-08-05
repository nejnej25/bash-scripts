#!/bin/bash
#Author: Perry

IPADDR=`ip a | grep eth0 | awk '{print $2}' | grep -v eth`
HOST=`hostname`
DNS=`cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -1`
GW=`ip route | grep default | awk '{print $3}'`
NET=`systemctl status network | grep Active | sed 's/   //g' | cut -f 2,3,4 -d:`
HTTPD=`systemctl status httpd | grep Active | sed 's/   //g' | cut -f 2,3,4 -d:`
F2B=`systemctl status fail2ban | grep Active | sed 's/   //g' | cut -f 2,3,4 -d:`
BIP=`fail2ban-client status sshd | grep list | cut -f 2 -d:`
IPTAB=`systemctl status iptables | grep Active | sed 's/   //g' | cut -f 2,3,4 -d:`
RSERV=`ss -atnlup | grep users | awk '{print $7}' | cut -f 2 -d: | cut -f 1 -d, | sed 's/((//' | sort -u | tr '\n' ' '`

LGREEN='\033[1;32m'
WHITE='\033[0m'

echo -e "${LGREEN}IP Address:${WHITE}\t$IPADDR"
echo -e "${LGREEN}Hostname:${WHITE}\t$HOST"
echo -e "${LGREEN}DNS:${WHITE}\t\t$DNS"
echo -e "${LGREEN}Default GW:${WHITE}\t$GW"
echo -e "${LGREEN}Network Status:${WHITE}$NET"

if [ $(rpm -qa httpd) ]; then
	echo -e "${LGREEN}HTTPD Status:${WHITE}  $HTTPD"
fi

if [ $(rpm -qa iptables) ]; then
	echo -e "${LGREEN}IPTables Status:${WHITE}$IPTAB"
fi

if [ $(rpm -qa fail2ban) ]; then
	echo -e "${LGREEN}F2B Status:  ${WHITE}  $F2B"
	echo -e "${LGREEN}Banned IP:${WHITE}$BIP"
fi

echo -e "${LGREEN}Listening Service/s: ${WHITE}$RSERV"
