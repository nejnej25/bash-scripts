#!/bin/bash

DESTDIR=/opt
TWMPDIR=${DESTDIR}/twemproxy
TWMPDIRSRC=${TWMPDIR}/src
TWMPDIRCONF=${TWMPDIR}/conf
LISTEN_IP=
REDIS_CACHE_IP=

# Update repo and system also install needed dependeices
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y build-essential gcc make libtool automake git

# Clone, configure and build twemproxy
sudo git -C ${DESTDIR} clone https://github.com/twitter/twemproxy.git
cd ${TWMPDIR} && sudo autoreconf -fvi && sudo ./configure --enable-debug=full > ~/tw-configure.log 2>&1 && sudo make > ~/tw-make.log 2>&1

# Check config file and populate
[ -f ${TWMPDIRCONF}/nutcracker.yml ] && sudo cp ${TWMPDIRCONF}/nutcracker.yml ${TWMPDIRCONF}/nutcracker.yml.orig
sudo bash -c "cat > ${TWMPDIRCONF}/nutcracker.yml <<-EOF
	cache:
	  listen: ${LISTEN_IP}:6379
	  hash: fnv1a_64
	  distribution: ketama
	  auto_eject_hosts: true
	  redis: true
	  timeout: 10000
	  server_retry_timeout: 100000
	  server_failure_limit: 2
	  servers:
	   - ${REDIS_CACHE_IP}:6379:1
EOF"

# System tweaks
sudo sed -ie '/# End of file/i root soft nofile 65000' /etc/security/limits.conf
sudo sed -ie '/# End of file/i * soft nofile 65000' /etc/security/limits.conf
sudo sed -ie '/# End of file/i * hard nofile 65000' /etc/security/limits.conf
sudo bash -c "cat > /etc/sysctl.d/11-twemproxy.conf <<-EOF
	net.ipv4.tcp_tw_reuse = 1
	net.ipv4.tcp_max_orphans = 262144
	net.ipv4.ip_local_port_range = 1024 65023
	net.ipv4.tcp_fin_timeout = 30
	net.core.netdev_max_backlog = 10000
	net.ipv4.tcp_syncookies = 1
	net.ipv4.conf.all.rp_filter = 1
	net.core.somaxconn = 60000
	net.ipv4.tcp_max_syn_backlog = 60000
	net.ipv4.tcp_synack_retries = 3
EOF"
sudo sysctl -p /etc/sysctl.d/11-twemproxy.conf

# Create systemd service
sudo bash -c "cat > /etc/systemd/system/twemproxy.service <<-EOF
	[Unit]
	Description=Service for twemproxy
	After=networking.target

	[Service]
	Type=forking
	ExecStart=${TWMPDIRSRC}/nutcracker -d -c ${TWMPDIRCONF}/nutcracker.yml -p /var/run/nutcracker.pid -o /var/log/twemproxy.log -v 2
	Restart=always
	RestartSec=2s

	[Install]
	WantedBy=multi-user.target
EOF"

# Run twemproxy
sudo systemctl enable twemproxy && sudo systemctl start twemproxy

# Install supervisor
sudo apt-get install -y supervisor
sudo systemctl stop supervisord

#GET SUPERVISOR CONF

# Populate supervisor log and start
sudo mkdir -p /var/log/supervisord
sudo touch /var/log/supervisord/supervisord.log
sudo systemctl restart supervisord
