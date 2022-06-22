#!/usr/bin/env bash

RASPI_IP=$1
echo "${RASPI_IP} proxy.local" | sudo tee -a /etc/hosts

ssh-keygen -t ed25519 -b 4096 -C 'proxy sysadmin' -f ~/.ssh/id_ed25519-sysadmin
ssh-copy-id -i ~/.ssh/id_ed25519-sysadmin -o PasswordAuthentication=yes sysadmin@proxy.local
ssh-keygen -t ed25519 -b 4096 -C 'proxy user' -f ~/.ssh/id_ed25519-proxyuser
ssh-copy-id -i ~/.ssh/id_ed25519-proxyuser -o PasswordAuthentication=yes proxyuser@proxy.local

echo -e "Host proxy-user\n\tHostName proxy.local\n\tUser proxyuser\n\tIdentityFile ~/.ssh/id_ed25519-proxyuser\n\tIdentitiesOnly yes\n\tDynamicForward 127.0.0.1:8118\n\n" >> ~/.ssh/config
echo -e "Host proxy-admin\n\tHostName proxy.local\n\tUser sysadmin\n\tIdentityFile ~/.ssh/id_ed25519-sysadmin\n\tIdentitiesOnly yes\n\n" >> ~/.ssh/config

echo 'Now ssh in "ssh proxy-admin"'
