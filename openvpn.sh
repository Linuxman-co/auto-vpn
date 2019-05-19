#!/bin/bash

OpenVPNPath=/etc/openvpn
GetInterface=$(ip add | grep ^[0-9] | awk 'NR==2 {print $2}' | tr -d ":")
Host=$(hostname)

echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Checking for updates\e[39m\e[0m"
sudo apt update
sudo apt dist-upgrade -y -q

echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Installing OpenVPN\e[39m\e[0m"
sudo apt install openvpn openssl mailutils zip -y -q
mkdir /var/log/openvpn
touch /var/log/openvpn/openvpn-status.log
touch /var/log/openvpn/openvpn.log

echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Copying Config Files\e[39m\e[0m"
sudo cp server.conf $OpenVPNPath/

echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Creating Server Certificates\e[39m\e[0m"
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Generating CA\e[39m\e[0m"
sudo openssl genrsa -out $OpenVPNPath/ca.key 2048
sudo openssl req -x509 -new -nodes -key $OpenVPNPath/ca.key -sha256 -days 1826 -subj "/C=./ST=./L=./O=./OU=./CN=$Host" -out $OpenVPNPath/ca.crt

echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Generating Certificate\e[39m\e[0m"
sudo openssl genrsa -out $OpenVPNPath/server.key 2048
sudo openssl req -new -sha256 -key $OpenVPNPath/server.key -subj "/C=./ST=./L=/O=./OU=./CN=$Host" -out $OpenVPNPath/server.csr
sudo openssl x509 -req -in $OpenVPNPath/server.csr -CA $OpenVPNPath/ca.crt -CAkey $OpenVPNPath/ca.key -out $OpenVPNPath/server.crt -days 365 -sha256

echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Generate Diffie-Hellman PEM\e[39m\e[0m"
sudo openssl dhparam -out $OpenVPNPath/dh2048.pem 2048

echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Generate TLS Key\e[39m\e[0m"
sudo openvpn --genkey --secret $OpenVPNPath/ta.key

echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Enabling IPv4 Forwarding\e[39m\e[0m"
echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf

echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Creating NAT in IPTables\e[39m\e[0m"
iptables -t nat -A POSTROUTING -o $GetInterface -j MASQUERADE
iptables -A FORWARD -i tun+ -o $GetInterface -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i tun+ -o $GetInterface -j ACCEPT

echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Installing IPTABLES-PERSISTENT\e[39m\e[0m"
sudo apt install iptables-persistent -y -q

echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Enabling OpenVPN on Startup\e[39m\e[0m"
sudo systemctl enable openvpn@server.service
sudo systemctl start openvpn@server.service

echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Checking Status\e[39m\e[0m"
status=$(systemctl status openvpn@server | grep Active | awk '{print $2 $3}')
if [ $status == 'active(running)' ]; then
    echo -e "\e[1m\e[32mComplete with no errors! Enjoy!\e[39m\e[0m"
    exit 0
fi
