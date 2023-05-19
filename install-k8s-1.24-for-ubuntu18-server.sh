#!/bin/sh

HOME_PATH='$HOME'

# requirement package list
if ! which wget > /dev/null; then
  echo 'Can not find wget, install with:'
  echo 'apt-get install wget'
  exit 1
fi

if ! which gpg > /dev/null; then
  echo 'Can not find GnUPG, install with:'
  echo 'apt-get install gnupg'
  exit 1
fi

if ! which git > /dev/null; then
  echo 'Can not find git, install with:'
  echo 'apt-get intsall git '
  exit 1
fi

cd $HOME_PATH

# disabled swap memory and firewall
echo -n "swap off memory ..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sleep 3
echo "OK!"

echo -n "inactive ufw ..."
ufw disable
sleep 3
echo "OK!"

if ! [[ "$PWD" = "$HOME" ]]; then 
  cd $HOME_PATH
fi

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


# Install Container runtime (cri-dockerd)
cd cri-dockerd

if ! [[ "$PWD" = "${HOME_PATH}/cri-dockerd" ]]; then 
  cd $HOME_PATH
fi

echo -n "Install the cri-dockerd ... (It will takes about 10~30 minutes)"

groupadd docker
usermod -aG docker $USER

mkdir bin
go build -o bin/cri-dockerd
mkdir -p /usr/local/bin
install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
cp -a packaging/systemd/* /etc/systemd/system
sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
systemctl daemon-reload
systemctl enable cri-docker.service
systemctl enable --now cri-docker.socket
systemctl restart cri-docker.socket

sleep 15
echo "OK!"


# Add the GPG key for kubernetes
echo -n "Add the GPG key for kubernetes ..."
cd ~
if ! [[ "$PWD" = "$HOME" ]]; then 
  cd $HOME_PATH
fi
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "OK!"

# Add the kubernetes repository
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
echo "OK!"

apt-get update


# Install Docker and Kubernetes packages.
echo -n "Install the kubernetes components ..."
apt-get install -y docker-ce kubelet=1.24.8-00 kubeadm=1.24.8-00 kubectl=1.24.8-00
apt-mark hold docker-ce kubelet kubeadm kubectl
echo "OK!"


# Enable the iptables bridge
echo -n "Enable the iptables bridge & sysctl params required by setup, params persist across reboots ..."
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

sleep 5

# sysctl params required by setup, params persist across reboots
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system
sleep 15
echo "OK!"