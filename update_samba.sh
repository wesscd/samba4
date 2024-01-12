#!/bin/bash

# Variáveis
SAMBA_VERSION="4.19.4"
SAMBA_DOWNLOAD_URL="https://download.samba.org/pub/samba/stable/samba-${SAMBA_VERSION}.tar.gz"
SAMBA_TAR_FILE="samba-${SAMBA_VERSION}.tar.gz"
SAMBA_SRC_DIR="samba-${SAMBA_VERSION}"

# Instale dependências
sudo apt-get update
sudo apt-get install -y build-essential libacl1-dev libattr1-dev libblkid-dev \
                       libgnutls28-dev libreadline-dev python3-dev python3-dnspython \
                       python3-gpg python3-markdown python3-ldb-dev python3-talloc-dev \
                       python3-tdb-dev python3-tk python3-crypto xsltproc docbook-xsl libcups2-dev

# Baixe o código-fonte do Samba
wget ${SAMBA_DOWNLOAD_URL}
tar -zxvf ${SAMBA_TAR_FILE}

# Configure, compile e instale
cd ${SAMBA_SRC_DIR}
./configure
make
sudo make install

# Reinicie os serviços do Samba
sudo systemctl restart smbd
sudo systemctl restart nmbd
sudo systemctl restart winbind

# Limpeza
cd ..
rm -rf ${SAMBA_SRC_DIR} ${SAMBA_TAR_FILE}
