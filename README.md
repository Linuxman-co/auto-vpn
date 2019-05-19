# auto-vpn
Easily create an anonymous VPN with Digital Ocean, no logs, destroy at any time with no trace.

# Instructions
1. CD Into temp or wherever you want to download the files

    `cd /tmp`

2. Download the files

    `git clone https://github.com/xlinuxmanx/auto-vpn.git`

3. CD Into the folder and make the scipt executable

    `cd auto-vpn`
    
    `chmod +x {openvpn.sh,win-client.sh}`
    
    During the setup, select **yes** on the prompts for IP Tables

4. Run the script

    `./openvpn.sh`
