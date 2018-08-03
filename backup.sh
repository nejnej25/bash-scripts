#!/bin/bash
#Author: Perry

if [ $# -eq 4 ]; then
	ipaddr=$1
	backup=$2
	name=$3
	destination=$4
else
	echo "Usage: backup.sh <ipaddr> <backup location> <backup name> <destination>"
	exit 2
fi

ping -c1 $ipaddr > /dev/null
if [ $? -ne 0 ]; then
	echo "Node $ipaddr is down.."
	exit 3
fi

tar -cvzf /tmp/$name-$(date +%F).tar.gz $backup
[ -f ~/.ssh/*.pub ] || echo "SSH keys not identified. Please set SSH key based auth(Preffered)."
echo "Sending to backup server.."
rsync -avh /tmp/$name-$(date +%F).tar.gz $USER@$ipaddr:$destination 
