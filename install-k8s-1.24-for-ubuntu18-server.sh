#!/bin/sh

# disabled swap memory
echo -n "swap off memory ..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
echo "OK!"

# Download the GPG key for docker
echo -n "Download the GPG key for docker ..."
wget -O - https://download.docker.com/linux/ubuntu/gpg > ./docker.key
gpg --no-default-keyring --keyring ./docker.gpg --import ./docker.key
gpg --no-default-keyring --keyring ./docker.gpg --export > ./docker-archive-keyring.gpg
mv ./docker-archive-keyring.gpg /etc/apt/trusted.gpg.d/
echo "OK!"

# Add the docker repository
echo -n "Add the docker repository ..."
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
echo "OK!"

# clone the repository
echo -n "Add the docker repository ..."
git clone https://github.com/Mirantis/cri-dockerd.git
echo "OK!"

# Login as root and run below commands
echo -n "Login as root and run below commands ..."
wget https://storage.googleapis.com/golang/getgo/installer_linux
chmod +x ./installer_linux
./installer_linux
source ~/.bash_profile

sleep 3
echo "OK!"