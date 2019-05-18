#!/bin/bash

display_usage() {
	echo "This script creates a configuration for Windows Systems"
	echo ""
	echo "Usage: ./win-client.sh <client-name> <email>"
}

create_client_config() {
	ClientDir=/etc/openvpn/$1
	ClientConf=/etc/openvpn/$1/$1.ovpn
	PublicIP=$(curl icanhazip.com)
	echo [*] Prepping Client Environment
	sudo mkdir $ClientDir/$1

	echo [*] Generating Client Cetificate for $1
	sudo openssl genrsa -out $ClientDir/$1.key 2048
	sudo openssl req -new -key $ClientDir/$1.key -out $ClientDir/$1.csr -subj "/C=US/ST=New York/L=New York City/O=Beeswax/OU=Nunya/CN=anonymous"
	sudo openssl x509 -req -days 365 -in $ClientDir/$1.csr -CA /etc/openvpn/ca.crt -CAkey /etc/openvpn/ca.key -set_serial 01 -out $ClientDir/$1.crt -nodes

	echo [*] Creating Config
	echo client >> $ClientConf
	echo dev tun >> $ClientConf
	echo dev-mnode OpenVPN >> $ClientConf
	echo proto tcp >> $ClientConf
	echo remote $PublicIP 1194 >> $ClientConf
	echo resolve-retry infinite >> $ClientConf
	echo nobind >> $ClientConf
	echo persist-key >> $ClientConf
	echo persist-tun >> $ClientConf
	echo ca ca.crt >> $ClientConf
	echo cert $1.crt >> $ClientConf
	echo key $1.key >> $ClientConf
	echo remote-cert-tls server >> $ClientConf
	echo tls-auth ta.key 1 >> $ClientConf
	echo cipher AES-256-CBC >> $ClientConf
	echo verb 0 >> $ClientConf

	echo [*] Copying CA and TA
	cp /etc/openvpn/ca.crt $ClientDir/
	cp /etc/openvpn/ta.key $ClientDir/

	echo [*] Compressing Client Config
	zip $ClientDir/$1.zip $ClientDir/*.*

	echo [*] Sending ZIP to $2
	echo "Attached is the VPN Client Config for $1" | mail -s "OpenVPN Client for $1" $2 -A $ClientDir/$1.zip
}

if [[ $USER -ne "root" ]]
then
	echo "Run as root!"
	exit 1
fi

if [[ ($# == "--help") || $# == "-h" ]]
then
	display_usage
	exit 0
fi

if [ $# -le 0 ]
then
	display_usage
	exit 1
fi


