#!/bin/bash

# Installation d'Ansible et Python
dnf update -y
dnf install -y ansible python

# Création de l'utilisateur avec des privilèges  et une conf en NOPASSWD pour une connexion sans mot de passe
useradd -m -s /bin/bash yrlan
echo "yrlan ALL=(ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/yrlan

# Ajout de la clé publique dans /home/yrlan/.ssh/authorized_keys pour une connexion sans mot de passe
mkdir -p /home/yrlan/.ssh
chmod 700 /home/yrlan/.ssh
touch /home/yrlan/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCwM32JCKeM4NyDV/6UX/5ZpVI8wr2PMRWysrYNEyvF/5MeKTzfk3aWmHS/heG5wMRpAC/mhgYLyuCDMlJKHFQZ4fBs8eGmsN2gxQ/W2RM1k1Y3+nzpiQRqOEdss79+wPNl4K+pdNcnnTWwOuk9268IBeiO9nkqsdDBoB3iJBLa0cnyPdJsHpnRuiLP1XoR0GECWjspGi7qD3lqs0Cw05jhB4EYY6N2V5hd1XahYHdh6dMRORp3CI7FZ/LxbzsA9LN5E2elv2VitkL4pS7yKOiupvkF7ybADpcLi4waT55AClrhgoeRgVpG2VVvZkr/BtLt6ZU9uyzoofQdKl21IuZ0FyofdMeU9q6AUwmZuZJwQ6e9D+LvrVNVu2Bm3OU1P1Q/VnJcRK9/92SyMjoh7oOOJhpxnzpDQ+8BmV4tQXxLklYZHdgRA05B7aH6NQBa6CzrP5sDreQAIiiWsHELcfyVPSa9bnhf7XMBkrQwzyeE+2Rv/X4Pb5Ox1zyUs0+O92zVC6z9i4pKQXpoHc27VhNK67NvIHKWN+bmgCA9oW5H5F6LKb48S05cLAXfkwURLZMN61JO8qNNok9k3y2Hl63isTeM4CASVpCKnIaEB2kdGW2ykUpxNFV3eCT3of8jTNRtq3LSi562KaOOJNWP1Uogw5NJtbZwCAab5jF2+EUHQQ== yrlan@MSI-9SEXR" |  tee /home/yrlan/.ssh/authorized_keys
chmod 600 /home/yrlan/.ssh/authorized_keys
chown -R yrlan:yrlan /home/yrlan/.ssh

# désactive SELinux
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config