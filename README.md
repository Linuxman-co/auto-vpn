# auto-vpn
Easily create an anonymous VPN with Digital Ocean, no logs, destroy at any time with no trace. You **can** use this for your own personal server if you wish but the whole purpose of this script is to create disposable VPN's in DigitalOcean or any other VPS Provider.

# Distributions
Ubuntu/Debian

# Instructions
1. CD Into temp or wherever you want to download the files

    `cd /tmp`

2. Download the files

    `git clone https://github.com/xlinuxmanx/auto-vpn.git`

3. CD Into the folder and make the scipt executable

    `cd auto-vpn`
    
    `chmod +x {openvpn.sh,win-client.sh}`
    
    During Postfix Configuration, select **Internet Site**, **system mail name** will be the hostname of your VPS.
    
    During the setup, select **yes** on the prompts for IP Tables

4. Run the script

    `./openvpn.sh`

# Windows Client
1. Run the win-client.sh script and add the client name followed by your email.

    `./win-client.sh Client-Name my@email.address`
    
    The Script will automatically generate a configuration file for this VPN and email it to you! (Check your spam)
