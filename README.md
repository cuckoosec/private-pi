# private-pi
Turn a Raspberry Pi into a dedicated internet privacy server

# Why

- Runs on a device you own (no cloud providers)
- Extensible, can be hardware controlled
- Teaches security, networking, Linux admin concepts

# Process
This guide is written for Debian 11 (specifically Raspi OS Lite 64-bit) but you can use any OS you like. The general process is this:

1. Flash your OS for the Pi (assumed complete)
2. Establish SSH communication
3. Secure the Pi
4. Install & configure DNS
5. Install & configure proxy service
6. Install & configure wireguard service
7. Configure proxy services

## SSH
Connect to the pi through the default user and create users relevant to the service. Create a strong password for the proxyadmin account which will be given super user privileges.

```bash
adduser proxyuser
adduser sysadmin
adduser sysadmin sudo

exit
```

Then, from the client connecting to the box:

```bash
RASPI_IP=192.168.1.1
echo "${RASPI_IP} proxy.local" | sudo tee -a /etc/hosts

ssh-keygen -t ed25519 -b 4096 -C 'proxy sysadmin' -f ~/.ssh/id_ed25519-sysadmin
ssh-copy-id -i ~/.ssh/id_ed25519-sysadmin -o PasswordAuthentication=yes sysadmin@proxy.local
ssh-keygen -t ed25519 -b 4096 -C 'proxy user' -f ~/.ssh/id_ed25519-proxyuser
ssh-copy-id -i ~/.ssh/id_ed25519-proxyuser -o PasswordAuthentication=yes proxyuser@proxy.local
```

Edit your `~/.ssh/config` file to include something like the following:

```bash
Host proxy-user
        HostName proxy.local           
        User proxyuser           
        Port 22      
        IdentityFile ~/.ssh/id_ed25519-proxyuser              
        IdentitiesOnly yes
        DynamicForward 127.0.0.1:8118  
                                                                                                                         
Host proxy-admin                             
        HostName proxy.local           
        User sysadmin
        Port 22                        
        IdentityFile ~/.ssh/id_ed25519-sysadmin                                 
        IdentitiesOnly yes
```

...And SSH in as the sysadmin.

## Configure DNS

```bash
sudo cp /etc/dnsmasq.conf{,.bak}
sudo touch /etc/dns-blocklist
sudoedit /etc/dnsmasq
```

With a backup of dnsmasq.conf in place, use this as a template to configure the service. This will:
- Answer DNS requests on the LAN
- Implement a blocklist

```bash
listen-address=192.168.1.1
addn-hosts=/etc/dns-blocklist
bogus-priv
cache-size=2000
domain-needed
no-poll
rebind-localhost-ok
stop-dns-rebind

```
Save and exit. Then, restart the service. See below for more details about resolving DNS through Tor.

Next, build your blocklist. DNS will answer for these hosts before leaving the LAN, a massive performance increase if you've never ran your own DNS. Sometimes blocklists have invalid hosts. We will clear out those issues first

```bash
curl -s http://sbc.io/hosts/alternates/fakenews-gambling-porn-social/hosts > /tmp/dns-blocklist
sudo cp -i /tmp/dns-blocklist /etc/dns-blocklist
sudo systemctl restart dnsmasq.service; systemctl status dnsmasq.service

echo 'Simple solution: just delete those lines. To do so I did this (you may have to change line numbers): '
sudo sed -e '23d' -e '46226d' -e '80711d' -e '128076d' /etc/dns-blocklist > /tmp/dns-blocklist
sudo cp -i /tmp/dns-blocklist /etc/dns-blocklist
sudo systemctl restart dnsmasq.service; systemctl status dnsmasq.service
```

You will have to configure the **hosts** to use this as a DNS server or instruct your router to use it as such. On another Debian machine the easiest way to do that is:

```bash
sudo unlink /etc/resolv.conf
echo -e "domain lan\nnameserver ${RASPI_IP}" | sudo tee /etc/resolv.conf
sudo systemctl restart systemd-resolved.service
systemctl status systemd-resolved.service
```

## Configure Proxy

This project was motivated by the speed, flexibility, etc of SOCKS proxies. This is because they are plug and play, reliable, and can be easily configured on a LAN. Added security is made possible by using SSH as a forwarding proxy, we'll do that in this case to demonstrate as this is a privacy- (read: security-) related exercise.

We will use privoxy to do so. "Privoxy is a free non-caching web proxy with filtering capabilities for enhancing privacy, manipulating cookies and modifying web page data and HTTP headers before the page is rendered by the browser." 

```bash
yes | sudo apt install privoxy
sudo cp /etc/privoxy/config{,.bak}
sudo cp /etc/privoxy/user.action{,.bak}

sudoedit /etc/privoxy/config
sudoedit /etc/privoxy/user.action

sudo systemctl restart privoxy.service; systemctl status privoxy.service
```

This is set to listen on the loopback interface because we'll preserve private HTTP and DNS requests by sending them through the SOCKS proxy. 

As it happens, the fast/easy/secure way to do this is through dynamically forwarding a port on our client machine, through the SSH tunnel, and to the privoxy service running on the Pi. SSH will act as a SOCKS server listen on that port and will forward from client localhost:8118 to server localhost:8118 (where the privoxy service is listening).

Privoxy processes the HTTP request and decides where to send it next, which in this case will be our VPN. Mullvad makes a SOCKS server available through its connection, but you can just as easily host your own private VPN and use the same SSH dynamic forwarding.

In `/etc/privoxy/config` this is controlled by the option `forward-socks5 / $IP:$PORT`. Mullvad makes 10.64.0.1 available for SOCKS5 with Wireguard. If you're using SSH tunnelling, use 127.0.0.1:$PORT (the one you're forwarding to the VPN server). Note that for increased privacy one could use the option `forward-socks5t / 127.0.0.1:9050` to forward privoxy requests through Tor.


## Configure VPN
Okay, our DNS and HTTP requests are being sent through a secure tunnel to the Pi. We're stripping ads, trackers, HTTP headers, and a bunch of other identifying information before we even leave the LAN, which is what we will do next.

If using Mullvad, follow the instructions on this page: [https://mullvad.net/en/help/wireguard-and-mullvad-vpn/](https://mullvad.net/en/help/wireguard-and-mullvad-vpn/)

And check from the Pi:

```bash
curl https://am.i.mullvad.net/json
```

Check for leaks: https://github.com/macvk/dnsleaktest

## Complete the circuit

Now, you can login as proxyuser over SSH

```bash
ssh -N proxy-user
```

Download FoxyProxy: https://addons.mozilla.org/en-US/firefox/addon/foxyproxy-standard/ and enter the following settings:

1. Proxy Type: SOCKS5
2. Proxy IP: 127.0.0.1
3. Port: 8118
4. Save & Edit Patterns
5. Blacklist as needed

Enable the proxy and head to https://mullvad.net/en/check/ or https://dnsleaktest.com/
