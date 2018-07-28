#!/bin/bash
#Created by: Perry
#This script is intended to use on limited distro and version only
#CentOS 6 and 7
#Ubuntu 16

#Must be root user
if [ $(id -u) -ne 0 ]; then
	echo "Only root user can run this script.."
	exit 3
fi

#Sufficient arguments
if [ $(echo $#) -ne 5 ]; then
	echo "Not sufficient information.."
	echo "Usage: spinup.sh hostname ipaddress netmask gateway dns"
	exit 4
fi

#Variables
HSTNAME=$1
IPADD=$2
MASK=$3
GATEWAY=$4
DNS=$5

main () {

##### FUNCTIONS ####################

sshd-config () {			
	#Configure sshd_config
        sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
        sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config
        sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/' /etc/ssh/sshd_config
        sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 0/' /etc/ssh/sshd_config
}

iptables-config () {
	#Iptables config
       	iptables -F
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -I INPUT -p tcp --dport 22 -j ACCEPT
        iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
		
	if [ $DIST == "CentOS" ]; then
		service iptables save
	elif [ $DIST =="Ubuntu" ]; then
iptables-save > /etc/iptables.rules
cat > /etc/network/if-pre-up.d/iptables <<EOF
#!/bin/bash
iptables-restore < /etc/iptables.rules
exit 0
EOF
	chmod 755 /etc/network/if-pre-up.d/iptables
	fi
}

####################################

	 
	 DIST=$( [ -f /etc/system-release ] && cat /etc/system-release | awk '{print $1}' || echo "Ubuntu" )

      	 #Get the version
	 if [ $DIST == "CentOS" ]; then
		VERS=$( [ -f /etc/os-release ] && cat /etc/os-release  | grep -i version_id | cut -f 2 -d\" || echo 6)
		if [ $VERS -eq 7 ]; then
			#Disable network manager
			systemctl stop NetworkManager && systemctl disable NetworkManager
			
			#Configure network and hostname
			hostnamectl set-hostname $HSTNAME
			NIC=$(ip a | grep ^2: | cut -f 2 -d: | sed 's/^ //')
			sed -i 's/BOOTPROTO="dhcp"/BOOTPROTO="none"/' /etc/sysconfig/network-scripts/ifcfg-$NIC
			echo -e "IPADDR=$IPADD\nNETMASK=$MASK\nGATEWAY=$GATEWAY\nDNS1=$DNS" >> /etc/sysconfig/network-scripts/ifcfg-$NIC
			systemctl restart network
			
			#Update and install packages
			yum update -y
			yum install epel-release yum-utils vim iptables-services bash-completion -y
			
			#Turnoff unwanted services and enable wanted
			systemctl stop firewalld && systemctl disable firewalld
			systemctl start iptables && systemctl enable firewalld

			#Configure iptables
			iptables-config

			#Configure time
			timedatectl set-timezone 'Asia/Manila'

			#Configure sshd_config
			sshd-config

			#Password strengthen
			sed -i 's/# difok = 5/difok = 5/' /etc/security/pwquality.conf
			sed -i 's/# minlen = 9/minlen = 9/' /etc/security/pwquality.conf
			sed -i 's/# dcredit = 1/dcredit = 1/' /etc/security/pwquality.conf
			sed -i 's/# ucredit = 1/ucredit = 1/' /etc/security/pwquality.conf
			sed -i 's/# ocredit = 1/ocredit = 1/' /etc/security/pwquality.conf
			sed -i 's/# maxrepeat = 0/maxrepeat = 3/' /etc/security/pwquality.conf
			sed -i 's/# gecoscheck = 0/gecoscheck = 1/' /etc/security/pwquality.conf
			sed -i 's/use_authtok/use_authtok remember=3/' /etc/pam.d/system-auth
			sed -i 's/PASS_MAX_DAYS   99999/PASS_MAX_DAYS   60/' /etc/login.defs
			sed -i 's/PASS_MIN_DAYS   0/PASS_MIN_DAYS   0/' /etc/login.defs
			sed -i 's/PASS_MIN_LEN    5/PASS_MIN_LEN    9/' /etc/login.defs
			sed -i 's/PASS_WARN_AGE   7/PASS_WARN_AGE   7/' /etc/login.defs	

		elif [ $VERS -eq 6 ]; then
			#Configure network and hostname
			sed -i '/HOSTNAME/d' /etc/sysconfig/network
			echo "HOSTNAME=$HSTNAME" >> /etc/sysconfig/network && hostname $HSTNAME
			NIC=$(ip a | grep ^2: | cut -f 2 -d: | sed 's/^ //')
			sed -i 's/BOOTPROTO=dhcp/BOOTPROTO=none/' /etc/sysconfig/network-scripts/ifcfg-$NIC
			echo -e "IPADDR=$IPADD\nNETMASK=$MASK\nGATEWAY=$GATEWAY\nDNS1=$DNS" >> /etc/sysconfig/network-scripts/ifcfg-$NIC
			service network restart

			#Update and install pacakges
			yum update -y
			yum install vim yum-utils bash-completion -y

			#Configure iptables
			iptables-config

			#Configure time
			ln -s /usr/share/zoneinfo/Asia/Manila /etc/localtime

			#Configure sshd_config
			sshd-config

			#Password strenghten
			sed -i 's/PASS_MAX_DAYS   99999/PASS_MAX_DAYS   60/' /etc/login.defs
			sed -i 's/PASS_MIN_DAYS   0/PASS_MIN_DAYS   0/' /etc/login.defs
			sed -i 's/PASS_MIN_LEN    5/PASS_MIN_LEN    9/' /etc/login.defs
			sed -i 's/PASS_WARN_AGE   7/PASS_WARN_AGE   7/' /etc/login.defs	
			sed -i 's/type=/type= difok=5 minlen=9 dcredit=1 ucredit=1 ocredit=1 maxrepeat=3 geckoscheck=1/' /etc/pam.d/system-auth
			sed -i 's/use_authtok/use_authtok remember=3/' /etc/pam.d/system-auth
		fi
	 elif [ $DIST == "Ubuntu" ]; then
		VERS=$( [ -f /etc/os-release ] && cat /etc/os-release  | grep -i version_id | cut -f 2 -d\" | cut -f 2 -d.)
		if [ $VERS -lt 17 ]; then
			#Disable network manager
			systemctl stop NetworkManager && systemctl disable NetworkManager
		
			#Configure network and hostname	
			hostnamectl set-hostname $HSTNAME
			NIC=$(ip a | grep ^2: | cut -f 2 -d: | sed 's/^ //')
			sed -i "/$NIC/d" /etc/network/interfaces
			echo -e "\nauto $NIC\niface $NIC inet static\naddress $IPADD\nnetmask $MASK\ngateway $GATEWAY\ndns-nameservers $DNS" >> /etc/network/interfaces	
			systemctl restart networking

			#Update and install packages
			apt-get update -y
			apt-get upgrade -y
			apt-get install -y vim bash-completion openssh-server

			#Iptables config
			iptables-config

			#Configure sshd_config
			sshd-config
		
		#elif [ $VERS -ge 17 ]; then
		fi
	 fi
}
main

