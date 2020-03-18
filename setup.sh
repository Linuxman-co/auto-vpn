#!/bin/bash

# Declare Variables
OpenVPNPath=/etc/openvpn
GetInterface=$(ip add | grep ^[0-9] | awk 'NR==2 {print $2}' | tr -d ":")
PublicIP=$(curl icanhazip.com)

# Update the system
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Checking for updates\e[39m\e[0m"
apt update
apt dist-upgrade -y -q

# Install required packages
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Installing Required Packages\e[39m\e[0m"
apt install openvpn openssl zip gzip apache2 squid -y -q
mkdir /var/log/openvpn
touch /var/log/openvpn/openvpn-status.log
touch /var/log/openvpn/openvpn.log

# Copy over the server config
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Copying Config Files\e[39m\e[0m"
cp server.conf $OpenVPNPath/

# Copy over the template CA Certificate and Key files
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Creating Server Certificates\e[39m\e[0m"
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Copying CA\e[39m\e[0m"
cp /usr/share/doc/openvpn/examples/sample-keys/{ca.crt,ca.key} $OpenVPNPath

# Copy over the templace Server Certificate and Key files
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Copying Certificate\e[39m\e[0m"
gzip -d /usr/share/doc/openvpn/examples/sample-keys/server.crt.gz
cp /usr/share/doc/openvpn/examples/sample-keys/{server.crt,server.key} $OpenVPNPath

# Generate the DHKey for the server
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Generate Diffie-Hellman PEM\e[39m\e[0m"
openssl dhparam -out $OpenVPNPath/dh2048.pem 2048

# Generate the TLS Key for the server
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Generate TLS Key\e[39m\e[0m"
openvpn --genkey --secret $OpenVPNPath/ta.key

# Enable IPv4 Forwarding
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Enabling IPv4 Forwarding\e[39m\e[0m"
echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf

# Configure interface routing in IPTables
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Creating NAT in IPTables\e[39m\e[0m"
iptables -t nat -A POSTROUTING -o $GetInterface -j MASQUERADE
iptables -A FORWARD -i tun+ -o $GetInterface -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i tun+ -o $GetInterface -j ACCEPT

# Install IP Tables Persistent
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Installing IPTABLES-PERSISTENT\e[39m\e[0m"
apt install iptables-persistent -y -q

# Enable OpenVPN on startup
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Enabling OpenVPN on Startup\e[39m\e[0m"
systemctl enable openvpn@server.service
systemctl start openvpn@server.service

# Check if OpenVPN is currently running, if it is, setup was sucessful
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Checking OpenVPN Status\e[39m\e[0m"
openvpn_status=$(systemctl status openvpn@server | grep active | awk '{print $2 $3}')
if [ $openvpn_status == 'active(running)' ]; then
    echo -e "\e[1m\e[32mComplete with no errors! Enjoy!\e[39m\e[0m"
fi

# Configure Apache2 so client configs can be downloaded via the web.
# Check if apache2 is running, if it is, stop it
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Configuring Apache2\e[39m\e[0m"
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Checking Apache2 Status\e[39m\e[0m"
apache2_status=$(systemctl status apache2.service | grep active | awk '{print $2 $3}')
if [ $apache2_status == 'active(running)' ]; then
    echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Apache2 is Running, stopping...\e[39m\e[0m"
    systemctl stop apache2.service
fi

# Disable Default Apache2 Site
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Disabling Default Site\e[39m\e[0m"
a2dissite 000-default.conf

# Create new apache2 site using SSL
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Copying and Setting Up Virtualhost for VPN Clients\e[39m\e[0m"
cp vpn-client.conf /etc/apache2/sites-available/
mkdir /var/www/vpn-client
mkdir /var/www/vpn-client/scripts
chmod a+rx /var/www/vpn-client/*.zip
chmod a+rx /var/www/vpn-client/scripts/*.pac
a2enmod ssl
a2ensite vpn-client.conf
htpasswd -b -c /var/www/vpn-client/.htpasswd vpn supersneaky
systemctl enable apache2.service
systemctl start apache2.service

# Check if apache started with no errors
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Checking Apache2 Status\e[39m\e[0m"
if [ $apache2_status == 'active(running)' ]; then
    echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Apache2 is Running with no errors!\e[39m\e[0m"
fi

# Configure SQUID
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Stopping Squid\e[39m\e[0m"
systemctl stop squid.service
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Setting up Squid\e[39m\e[0m"
mv /etc/squid/squid.conf /etc/squid/squid.conf.org
cp squid.conf /etc/squid/squid.conf

# Creating PAC Script
pac_file=/var/www/vpn-client/scripts/proxy.pac
echo "function FindProxyForURL(url, host) {" >> $pac_file
echo "return \"PROXY $PublicIP:3128; DIRECT\"" >> $pac_file
echo "}" >> $pac_file
chmod a+rx $pac_file

echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Setup Complete, starting Squid\e[39m\e[0m"
systemctl enable squid.service
systemctl start squid.service

# Check if squid started with no errors
squid_status=$(systemctl status squid.service | grep active | awk '{print $2 $3}')
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Checking Squid Status\e[39m\e[0m"
if [ $squid_status == 'active(running)' ]; then
    echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Squid is Running with no errors!\e[39m\e[0m"
fi

echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Your configuration files can now be downloaded from https://$PublicIP/\e[39m\e[0m"
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Use the following to authenticate:\e[39m\e[0m"
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Username: vpn\e[39m\e[0m"
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Password: supersneaky\e[39m\e[0m"
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Proxy Address: $PublicIP:3128\e[39m\e[0m"
echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Proxy PAC Script: https://$PublicIP/scripts/proxy.pac\e[39m\e[0m"

# Reboot the system so IP Forwarding works
read -p "For the VPN to work, we need to reboot the VPN. Make sure you know the user/pass for the website to download the config files.\nPress Enter when you're ready..."
reboot
