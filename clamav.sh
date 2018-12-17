#!/bin/bash
#Author: Perry
#For CentOS

if [ $(id -u) -ne 0 ]; then
	echo 'Please run this script as root..'
	exit 1
fi

if [ $# -ne 2 ]; then
	echo 'Usage: clamav.sh <from addr> <to addr>'
	exit 2
fi

#Check epel repo
rpm -q epel-release
if [ $? = 1]; then
	echo 'Installing epel repo..'
	yum install epel-release -y > /dev/null 2>&1
fi

#Install clamav packages
echo 'Installing clamav packages..'
yum install -y clamav clamav-update clamav-scanner-sysvinit > /dev/null 2>&1

#Configuring clamav
[ -f /etc/freshclam.conf ] && FRESH_CONF=/etc/freshclam.conf || echo 'Cannot find freshclam.conf file exiting..' && exit
[ -f /etc/clamd.d/scan.conf ] && SCAN_CONF=/etc/clamd.d/scan.conf || echo 'Cannot find scan.conf file exiting..' && exit
sed -i 's/Example/#Example/' $FRESH_CONF
sed -i 's:#DatabaseDirectory /var/lib/clamav:DatabaseDirectory /var/lib/clamav:' $FRESH_CONF
sed -i 's:#UpdateLogFile /var/log/freshclam.log:UpdateLogFile /var/log/freshclam.log:' $FRESH_CONF
sed -i 's/#DatabaseOwner clamupdate/DatabaseOwner clamupdate/' $FRESH_CONF
freshclam

sed -i 's/Example/#Example/' $SCAN_CONF
sed -i 's:#LocalSocket /var/run/clamd.scan/clamd.sock:LocalSocket /var/run/clamd.scan/clamd.sock:' $SCAN_CONF
sed -i 's/#FixStaleSocket yes/FixStaleSocket yes/' $SCAN_CONF
sed -i 's/#TCPSocket 3310/TCPSocket 3310/' $SCAN_CONF
sed -i 's/#TCPAddr 127.0.0.1/TCPAddr 127.0.0.1/' $SCAN_CONF

#Enabling service
systemctl start clamd.scan || service clamd.scan
systemctl enable clamd.scan || chkconfig clamd.scan on

sudo ln -s /etc/clamd.d/scan.conf /etc/clamd.conf
#Test Scan
clamdscan .
freshclam

#Script for auto scan
SCRIPT=/opt/virusscan.sh
cat > $SCRIPT <<-EOF
 	#!/bin/bash
	PATH=/usr/bin:/bin

	# Start log output
	logger "[Info] ClamAV Scan Start"

	fromAddr="$FR"
	toAddr="$TO"
	subjString="[AWS] Virus Found in `hostname`"


	# clamd update
	yum -y --enablerepo=rpmforge update clamd > /dev/null 2>&1
	freshclam > /dev/null 2>&1

	# excludeopt setup
	excludelist=/opt/scripts/clamav/clamscan.exclude
	if [ -s $excludelist ]; then
	    for i in `cat $excludelist`
	    do
	        if [ $(echo "$i"|grep \/$) ]; then
	            i=`echo $i|sed -e 's/^\([^ ]*\)\/$/\1/p' -e d`
	            excludeopt="${excludeopt} --exclude-dir=^$i"
	        else
	            excludeopt="${excludeopt} --exclude=^$i"
	        fi
	    done
	fi

	# virus scan
	CLAMSCANTMP=`mktemp`
	clamscan --recursive --remove ${excludeopt} / > $CLAMSCANTMP 2>&1
	bodyString="`grep FOUND$ $CLAMSCANTMP`"
	[ ! -z "$(grep FOUND$ $CLAMSCANTMP)" ] && \

	# report mail send
	echo -e "From: ${fromAddr}\nTo: ${toAddr}\nSubject:${subjString}\n\n${bodyString}" | /usr/sbin/sendmail -t ${toAddr} -froot

	# Log output virus detection
	grep FOUND$ $CLAMSCANTMP | logger

	rm -f $CLAMSCANTMP

	# End log output
	logger "[Info] ClamAV Scan Finish"
EOF
chmod 755 $SCRIPT

#Exclude special directories on scan
EXCLUDE=/opt/clamscan.exclude
echo '/proc/' >> $EXCLUDE
echo '/sys/' >> $EXCLUDE

#Set daily job to cron
ln -s $SCRIPT /etc/cron.daily/virusscan.sh

#Optional check, file that will hit by clamav
#wget -q http://www.eicar.org/download/eicar.com.txt
#wget -q http://www.eicar.org/download/eicar_com.zip
#wget -q http://www.eicar.org/download/eicarcom2.zip
