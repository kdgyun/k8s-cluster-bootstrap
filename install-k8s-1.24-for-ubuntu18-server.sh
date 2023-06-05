#! /usr/bin/env bash

# Return true if we pass in an IPv4 pattern.
valid_ip() {
  rx="([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])"

  if [[ $1 =~ ^$rx\.$rx\.$rx\.$rx$ ]]; then
    if [[ "$1" == *192.168.*.* ]]; then
      echo "IP addresses in the 192.168.0.0/16 range cannot be used."
      return 0
    fi
    return 1
  else
    echo "Incorrect format IP address : $1"
    return 0
  fi
}

# bool function to test if the user is root or not
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Please run as root"
  exit 1
fi

VALID_PARAM1=false
VALID_PARAM2=false
WORKER=false
OPT_REGULAR_USER=false
while (( "$#" )); do
  case "$1" in
    -i|--ip)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        HOST_IP=$2
        VALID_PARAM2=true
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -r|--regularuser)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        REGULAR_USER_PATH=$2
        OPT_REGULAR_USER=true
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -m|--master)
        MASTER=true
        VALID_PARAM1=true
        shift
      ;;
    -w|--worker)
        WORKER=true
        VALID_PARAM1=true
        shift
      ;;
    -h|--help)
      echo "Usage:  $0 [options] <value>" >&2
      echo "        -h | --help                                       This help text" >&2
      echo "        -i | --ip <Host IP>                               host-ip(master node) configuration for kubernetes. but can't use range of 192.168.0.0/16" >&2
      echo "        -m | --master                                     Set to initialize as a master node." >&2
      echo "        -r | --regularuser <HOME_PATH_OF_REGULAR_USER>    Allow regular users to access kubernetes." >&2
      echo "        -w | --worker                                     Set to initialize as a worker node." >&2
      exit 0
      ;;
    -*|--*) # unsupported flags
      echo "Error: Unsupported flag: $1" >&2
      echo "$0 -h for help message" >&2
      exit 1
      ;;
    *)
      echo "Error: Arguments with not proper flag: $1" >&2
      echo "$0 -h for help message" >&2
      exit 1
      ;;
  esac
done

if [[ $VALID_PARAM1 == false ]]; then
  echo "Error: Arguments with not proper flag: -m/--master or -w/--worker" >&2
  echo "$0 -h for help message" >&2
  exit 1
elif [[ $MASTER == true ]] && [[ $WORKER == true ]]; then
  echo "Both options(-m and -w) cannot be used together." >&2
  exit 1
elif [[ $VALID_PARAM2 == false ]]; then
  echo "Error: Arguments with not proper flag: -i/--ip" >&2
  echo "$0 -h for help message" >&2
  exit 1
fi
# check Host-IP
if [[ "$HOST_IP" -eq 1 ]]; then
  echo "No IP argument supplied."
  echo "Please run with IP address like x.x.x.x"
fi

if valid_ip "$HOST_IP" ; then
  exit 1
fi

HOME_PATH=$HOME
echo "Home path is $HOME_PATH"

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
echo "swap off memory ..."
echo
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sleep 3
echo 'Success!'
echo '========================================='
echo

echo -n "inactive ufw ..."
ufw disable
sleep 3
echo "OK!"
echo

if ! [[ "$PWD" = "$HOME_PATH" ]]; then 
  cd $HOME_PATH
fi

# update and install packages needed to use the Kubernetes
echo "Download the GPG key for docker ..."
apt-get update
apt-get install -y apt-transport-https ca-certificates curl
echo 'Success!'
echo '========================================='
echo
echo

# Download the GPG key for docker
echo "Download the GPG key for docker ..."
echo
wget -O - https://download.docker.com/linux/ubuntu/gpg > ./docker.key
gpg --no-default-keyring --keyring ./docker.gpg --import ./docker.key
gpg --no-default-keyring --keyring ./docker.gpg --export > ./docker-archive-keyring.gpg
mv ./docker-archive-keyring.gpg /etc/apt/trusted.gpg.d/
echo 'Success!'
echo '========================================='
echo
echo

# Add the docker repository
echo "Add the docker repository ..."
echo
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
groupadd docker
usermod -aG docker $USER
echo 'Success!'
echo '========================================='
echo
echo

# clone the repository
echo "Add the docker repository ..."
git clone https://github.com/Mirantis/cri-dockerd.git
echo 'Success!'
echo '========================================='
echo
echo

# Login as root and run below commands
echo "Login as root and run below commands ..."
wget https://storage.googleapis.com/golang/getgo/installer_linux
chmod +x ./installer_linux
./installer_linux
source ~/.bash_profile

sleep 3
echo 'Success!'
echo '========================================='
echo
echo


# Install Container runtime (cri-dockerd)
cd cri-dockerd

if ! [[ "$PWD" = "${HOME_PATH}/cri-dockerd" ]]; then 
  cd $HOME_PATH
fi

echo "Install the cri-dockerd ... (It will takes about 10~30 minutes)"
echo

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
echo 'Success!'
echo '========================================='
echo
echo


# Add the GPG key for kubernetes
echo "Add the GPG key for kubernetes ..."
cd $HOME_PATH
if ! [[ "$PWD" = "$HOME_PATH" ]]; then 
  cd $HOME_PATH
fi
curl -fsLo /usr/share/keyrings/kubernetes-archive-keyring.gpg http://echo-bio.cn:8888/kubernetes-archive-keyring.gpg
echo 'Success!'
echo '========================================='
echo
echo

# Add the kubernetes repository
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
echo 'Success!'
echo '========================================='
echo
echo

# Update apt-get
apt-get update
if [[ $? -ne 0 ]]; then
  apt-get update >> apt-get-update.log
  echo 'Fail....'
  grep -o 'NO_PUBKEY.*' apt-get-update.log | while read -r _ key; do 
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key"
    break
  done
  rm apt-get-update.log
  
  apt-get update >> apt-get-update.log

  if [[ $? -ne 0 ]]; then
    echo 'Fail.... 2 '
    curl -fsSLo /etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

    rm apt-get-update.log
  fi
  apt-get update
fi


# Install Docker and Kubernetes packages.
echo "Install the kubernetes components ..."
apt-get install -y docker-ce kubelet=1.24.8-00 kubeadm=1.24.8-00 kubectl=1.24.8-00
apt-mark hold docker-ce kubelet kubeadm kubectl
echo 'Success!'
echo '========================================='
echo
echo


# Enable the iptables bridge
echo "Enable the iptables bridge & sysctl params required by setup, params persist across reboots ..."
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

# init master node
if [[ $MASTER == true ]]; then
  LINE="========================\n\n"
  INITKUBECONFIG=$(kubeadm init --kubernetes-version=v1.24.0 --apiserver-advertise-address=$HOST_IP --pod-network-cidr=192.168.0.0/16 --cri-socket=unix:///var/run/cri-dockerd.sock \
    -1)
  echo $LINE
  echo "$INITKUBECONFIG"
  echo "${INITKUBECONFIG}"
  mkdir -p $HOME_PATH/.kube
  cp -i /etc/kubernetes/admin.conf $HOME_PATH/.kube/config
  chown $(id -u):$(id -g) $HOME_PATH/.kube/config

  if [[ $OPT_REGULAR_USER == true ]]; then
    mkdir -p $REGULAR_USER_PATH/.kube
    cp -i /etc/kubernetes/admin.conf $REGULAR_USER_PATH/.kube/config
    chown $(id -u):$(id -g) $REGULAR_USER_PATH/.kube/config
  fi
fi