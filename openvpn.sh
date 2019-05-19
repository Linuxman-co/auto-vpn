#!/bin/bash

OpenVPNPath=/etc/openvpn
GetInterface=$(ip add | grep ^[0-9] | awk 'NR==2 {print $2}' | tr -d ":")

echo [*] Checking for updates
sudo apt update
sudo apt dist-upgrade -y

echo [*] Installing OpenVPN\n
sudo apt install openvpn openssl mailx -y -q

echo [*] Copying Config Files\n
sudo cp server.conf /etc/openvpn/

echo [*] Creating Server Certificates
echo [*] Generating CA
sudo openssl genrsa -out $OpenVPNPath/ca.key 2048
sudo openssl req -new -x509 -days 1826 -key $OpenVPNPath/ca.key -out $OpenVPNPath/ca.crt -subj "/C=US/ST=New York/L=New York City/O=Beeswax/OU=Nunya/CN=anonymous"

echo [*] Generating Certificate
sudo openssl genrsa -out $OpenVPNPath/server.key 2048
sudo openssl req -new -key $OpenVPNPath/server.key -out $OpenVPNPath/server.csr -subj "/C=US/ST=New York/L=New York City/O=Beeswax/OU=Nunya/CN=anonymous"
sudo openssl x509 -req -days 365 -in $OpenVPNPath/server.csr -CA $OpenVPNPath/ca.crt -CAkey $OpenVPNPath/ca.key -set_serial 01 -out $OpenVPNPath/server.crt -nodes

echo [*] Generate Diffie-Hellman PEM
sudo openssl dhparam -out $OpenVPNPath/dh2048.pem 2048

echo [*] Generate TLS Key
sudo openvpn --genkey --secret $OpenVPNPath/ta.key

echo [*] Enabling IPv4 Forwarding
echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf

echo [*] Creating NAT in IPTables
iptables -t nat -A POSTROUTING -o $GetInterface -j MASQUERADE
iptables -A FORWARD -i tun+ -o $GetInterface -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i tun+ -o $GetInterface -j ACCEPT

echo [*] Installing IPTABLES-PERSISTENT
sudo apt install iptables-persistent -y -q

echo [*] Enabling OpenVPN on Startup
sudo systemctl enable openvpn@server.service
sudo systemctl start openvpn@server.service
