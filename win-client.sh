#!/bin/bash

display_usage() {
	echo "This script creates a configuration for Windows Systems"
	echo ""
	echo "Usage: ./win-client.sh <client-name> <email>"
}

create_client_config() {
	ClientDir=/etc/openvpn/$1
	ClientConf=/etc/openvpn/$1/$1.ovpn
	PublicIP=$(curl -s icanhazip.com)
	Host=$(hostname)
	echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Prepping Client Environment\e[0m\e[39m"
	sudo mkdir $ClientDir

	echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Generating Client Cetificate for $1\e[0m\e[39m"
	sudo openssl genrsa -out $ClientDir/$1.key 2048
	sudo openssl req -new -sha256 -key $ClientDir/$1.key -out $ClientDir/$1.csr -subj "/C=./ST=./L=./O=./OU=./CN=$Host" -nodes
	sudo openssl x509 -req -days 365 -in $ClientDir/$1.csr -CA /etc/openvpn/ca.crt -CAkey /etc/openvpn/ca.key -out $ClientDir/$1.crt -sha256

	echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Creating Config\e[0m\e[39m"
	echo client >> $ClientConf
	echo dev tun >> $ClientConf
	echo dev-node OpenVPN >> $ClientConf
	echo proto tcp >> $ClientConf
	echo remote $PublicIP 1194 >> $ClientConf
	echo resolv-retry infinite >> $ClientConf
	echo nobind >> $ClientConf
	echo persist-key >> $ClientConf
	echo persist-tun >> $ClientConf
	echo ca ca.crt >> $ClientConf
	echo cert $1.crt >> $ClientConf
	echo key $1.key >> $ClientConf
	echo remote-cert-tls server >> $ClientConf
	echo tls-auth ta.key 1 >> $ClientConf
	echo cipher AES-256-CBC >> $ClientConf
	echo verb 3 >> $ClientConf

	echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Copying CA and TA\e[0m\e[39m"
	cp /etc/openvpn/ca.crt $ClientDir/
	cp /etc/openvpn/ta.key $ClientDir/

	echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Compressing Client Config\e[0m\e[39m"
	zip $ClientDir/$1.zip $ClientDir/*.*

	echo -e "\e[1m\e[32m[\e[1m\e[31m*\e[1m\e[32m] Sending ZIP to $2\e[0m\e[39m"
	echo "Attached is the VPN Client Config for $1" | mail -s "OpenVPN Client for $1" $2 -A $ClientDir/$1.zip
	
	echo -e "\e[1m\e[32mClient configuration has been emailed! Check your spam\e[0m\e[39m"
}

if [[ $USER -ne "root" ]]
then
	echo -e "\e[1m\e[31mRun as root!\e[39m\e[0m"
	exit 1
fi

if [[ ($# == "--help") || $# == "-h" ]]
then
	display_usage
	exit 0
fi

if [ $# -le 1 ]
then
	display_usage
	exit 1
fi

create_client_config "$1" "$2"
