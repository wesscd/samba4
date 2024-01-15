#!/bin/bash

# Função para solicitar informações ao usuário
get_user_input() {
    read -p "$1: " user_input
    echo "$user_input"
}

# Atualizar e instalar NetworkManager
sudo apt update && sudo apt upgrade
sudo apt install network-manager -y

# Configurar rede
cat <<EOL | sudo tee /etc/netplan/00-installer-config.yaml
network:
  version: 2
  renderer: NetworkManager
EOL

sudo netplan apply

# Configurar DNS
sudo mkdir -p /etc/NetworkManager/conf.d/
echo -e "[main]\ndns=" | sudo tee /etc/NetworkManager/conf.d/dns.conf
sudo systemctl restart NetworkManager.service

# Ajustar data e hora
sudo timedatectl set-timezone "$(get_user_input 'Informe a Timezone (ex: America/Sao_Paulo)')"
sudo apt install ntp ntpdate -y
sudo service ntp stop
sudo ntpdate "$(get_user_input 'Informe o servidor NTP (ex: a.ntp.br)')"
sudo service ntp start

# Instalar pacotes e Samba
sudo apt-get install wget acl attr autoconf bind9utils bison build-essential debhelper dnsutils docbook-xml docbook-xsl flex gdb libjansson-dev krb5-user libacl1-dev libaio-dev libarchive-dev libattr1-dev libblkid-dev libbsd-dev libcap-dev libcups2-dev libgnutls28-dev libgpgme-dev libjson-perl libldap2-dev libncurses5-dev libpam0g-dev libparse-yapp-perl libpopt-dev libreadline-dev nettle-dev perl pkg-config python-all-dev python2-dbg python-dev-is-python2 python3-dnspython python3-gpg python3-markdown python3-dev xsltproc zlib1g-dev liblmdb-dev lmdb-utils libsystemd-dev perl-modules-5.30 libdbus-1-dev libtasn1-bin -y

cd /usr/src/
sudo wget -c https://download.samba.org/pub/samba/stable/samba-4.14.7.tar.gz
sudo tar -xf samba-4.14.7.tar.gz && cd samba-4.14.7

./configure --with-systemd --prefix=/usr/local/samba --enable-fhs
sudo make && sudo make install

echo "PATH=\$PATH:/usr/local/samba/bin:/usr/local/samba/sbin" | sudo tee -a /root/.bashrc
source /root/.bashrc

sudo cp -v /usr/src/samba-4.14.7/bin/default/packaging/systemd/samba.service /etc/systemd/system/samba-ad-dc.service
sudo mkdir -v /usr/local/samba/etc/sysconfig

echo "SAMBAOPTIONS=\"-D\"" | sudo tee /usr/local/samba/etc/sysconfig/samba

sudo systemctl daemon-reload
sudo systemctl enable samba-ad-dc.service

# Provisionamento ou Criação do Domínio
sudo systemctl stop systemd-resolved.service
sudo systemctl disable systemd-resolved.service

# Configurar DNS no NetworkManager
sudo nmtui

# Atualizar /etc/hosts
sudo sed -i "s/127.0.0.1 localhost/127.0.0.1 localhost\n$(get_user_input 'Informe o IP do servidor') $(get_user_input 'Informe o FQDN do servidor')/" /etc/hosts

# Provisionar o domínio
sudo samba-tool domain provision --use-rfc2307 --domain="$(get_user_input 'Informe o nome do domínio')" --realm="$(get_user_input 'Informe o realm do domínio')"
sudo samba-tool user setpassword administrator

sudo cp -bv /usr/local/samba/var/lib/samba/private/krb5.conf /etc/krb5.conf
sudo systemctl start samba-ad-dc.service
