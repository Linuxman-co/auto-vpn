# Auto VPN & Proxy
Easily create an anonymous VPN and Proxy with Digital Ocean, no logs, destroy at any time with no trace. You **can** use this for your own personal server if you wish but the whole purpose of this script is to create disposable VPN's in DigitalOcean or any other VPS Provider. (D.O. confirmed they do not track what goes on within the VPS).

# Distributions
Ubuntu

# Instructions
1. Download the files

    `git clone https://github.com/xlinuxmanx/auto-vpn.git`

2. CD Into the folder and make the scipt executable

    `cd auto-vpn`
    
    `chmod +x {setup.sh,win-client.sh}`

3. Run the script

    `./setup.sh`
    
    During Updates, you may be asked which grub configuration to use, just select to keep the current (default selected)
    
    During the setup, select **yes** on the prompts for IP Tables
   
4. At the end of the script, you will be given a URL including user/pass to download the config files later as well as the proxy address and port to use in either your browser or network settings.. Take a note of it!
 
# Windows Client
1. Run the win-client.sh script and add the client name.

    `./win-client.sh Client-Name`
    
    The Script will automatically generate a configuration file for this VPN and make it available from the URL provided earlier during setup. If you forget the URL, its just `https://<VPS IP>/<client name>.zip`.
    
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
  
  Then click ***OK*** and ***Save***.
  
  10. Now you should be able to connect to it from the connections applet.
