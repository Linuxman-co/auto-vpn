# Auto VPN
Easily create an anonymous VPN with Digital Ocean, no logs, destroy at any time with no trace. You **can** use this for your own personal server if you wish but the whole purpose of this script is to create disposable VPN's in DigitalOcean or any other VPS Provider. (D.O. confirmed they do not track what goes on within the VPS).

# Distributions
Ubuntu

# VPS Note
~~When creating a Droplet in Digital Ocean, make the hostname something "normal" instead of the gibberish it automaticaly generates or the script will have trouble sending emails because of spam filters.~~
Google and other mail providers increased security to prevent spam, so changing the hostname of the VPS won't allow your emails to reach even the spam folder anymore, you will have to transfer the ZIP file using SCP to your computer now or until i figure out an easier way to do this. When using SCP, the config zip archive is located in `/etc/openvpn/(clientname)`

# Instructions
1. CD Into temp or wherever you want to download the files

    `cd /tmp`

2. Download the files

    `git clone https://github.com/xlinuxmanx/auto-vpn.git`

3. CD Into the folder and make the scipt executable

    `cd auto-vpn`
    
    `chmod +x {openvpn.sh,win-client.sh}`

4. Run the script

    `./openvpn.sh`
    
    During Updates, you may be asked which grub configuration to use, just select to keep the current (default selected)
    
    During Postfix Configuration, select **Internet Site**, **system mail name** will be the hostname of your VPS.
    
    During the setup, select **yes** on the prompts for IP Tables
    
  ***5. Make sure you download the client config zip using SCP as mentioned earlier.***

# Windows Client
1. Run the win-client.sh script and add the client name followed by your email.

    `./win-client.sh Client-Name my@email.address`
    
    The Script will automatically generate a configuration file for this VPN and email it to you! (Check your spam)
    
    ***NOTE:*** As mentioned before, this may or may not work with your email provider due to better spam filters now.
    
2. After installing the OpenVPN Client in Windows, rename the tun interface it creates to "OpenVPN" so the config works as it should.

3. In the ZIP, copy its contents to your OpenVPN Directory in `C:\Users\<your username>\OpenVPN\config\`.

# Linux Client
For linux, it is easier to just configure the VPN connection using the Network Manager Interface. If you want to connect to the VPN via the CLI, you will have to go through the trouble of creating the TUN interface yourself so OpenVPN can tap into it.
1. Open the ***"Edit Connections"*** window.
2. Select the ***"+"*** to add a new connection.
3. Select ***OpenVPN*** from the dropdown and click ***Create***.
4. Give the connection a name.
5. In the ***VPN*** tab, add the following:

 - ***Gateway:*** VPS IP Address
 - ***Type:*** Certificate (TLS)
 - ***CA certificate:*** ca.crt
 - ***User certificate:*** client.crt
 - ***User private key:*** client.key
 
 6. In the same VPN tab, click on ***Advanced***.
 7. In the ***Advanced*** window under the ***General*** tab, select:
 
 - ***Use a TCP connection***
 - ***Set virtual device type:*** TUN
 
 8. In the ***Security*** tab, select the ***Cipher*** to be ***AES-256-CBC***.
 9. In the ***TLS Authentication*** tab, select:
 
  - ***Mode:*** TLS-Auth
  - ***Key File:*** ta.key
  - ***Key Direction:*** 1
  
  Then click ***OK***.
