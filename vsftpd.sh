#!/bin/bash
#Author: Perry

if [ $(id -u) -ne 0 ]; then
	echo "Please run this script with root privileges.."
	exit 2
fi

conf=/etc/vsftpd/vsftpd.conf

rpm -q vsftpd > /dev/null || yum install -y vsftpd > /tmp/yum-vsftpd.log 2>&1
[ -f $conf ] && cp $conf /etc/vsftpd/vsftpd.orig || echo "Failed to search configuration file please check.." && exit 2
[ -f /etc/vsftpd/vsftpd.orig ] && echo "Backing up original file to vsftpd.orig.." || echo "Failed to backup original config file please check.."

if [ -f $conf ]; then
	echo "Modifying configuration file.."
	sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' $conf
	sed -i '/#ascii_upload_enable=YES/s/#// ; /#ascii_download_enable=YES/s/#//' $conf
	sed -i '/#chroot_local_user=YES/s/#//' $conf
	sed -i '100a\allow_writeable_chroot=YES' $conf
	sed -i 's/listen=NO/listen=YES/ ; s/listen_ipv6=YES/listen_ipv6=NO/' $conf
	echo "use_localtime=YES" >> $conf

	#Passive mode
	echo -e "\n\n#passive mode\npasv_enable=YES\npasv_min_port=21000\npasv_max_port=21010" >> $conf
	systemctl restart vsftpd
	systemctl enable vsftpd
else
	echo "Failed to search configuration file please check.."
	exit 2
fi

#SELinux
echo "Changing SELinux boolean.."
setsebool -P ftpd_full_access=on 
setsebool -P tftp_home_dir=on 
setsebool -P ftpd_use_passive_mode=on

#IPTables
echo "Changing IPTables.."
iptables -I INPUT -p tcp --dport 21 -j ACCEPT
iptables -I INPUT -p tcp -m multiport --dports 21000:21010 -j ACCEPT
service iptables save > /dev/null

#FTP Module
echo "Load kernel module.."
modprobe ip_conntrack_ftp

echo "VSFTP is ready.."
