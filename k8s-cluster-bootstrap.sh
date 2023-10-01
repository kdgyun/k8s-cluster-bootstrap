#! /usr/bin/env bash

# prints colored text
printstyle() {
  if [[ "$2" == "info" ]]; then
    COLOR="96m";
  elif [[ "$2" == "success" ]]; then
    COLOR="92m";
  elif [[ "$2" == "warning" ]]; then
    COLOR="93m";
  elif [[ "$2" == "danger" ]]; then
    COLOR="91m";
  else #default color
    COLOR="0m";
  fi
  STARTCOLOR="\e[$COLOR";
  ENDCOLOR="\e[0m";
  if [[ "$2" == "danger" ]]; then
    printf "$STARTCOLOR%b$ENDCOLOR" "$1" >&2;
  else
    printf "$STARTCOLOR%b$ENDCOLOR" "$1"
  fi
}

# Return true if a value match in an name of container runtimes.
valid_container_name() {
  if [[ "$1" == "containerd" ]]; then
    CRI_SOCKET="unix:///run/containerd/containerd.sock"
    USED_CONTAINERD=true
    return 1
  elif [[ "$1" == "docker" ]]; then
    CRI_SOCKET="unix:///var/run/cri-dockerd.sock"
    USED_CONTAINERD=false
    return 1
  else
    printstyle "Container runtime name is invalid : $1 \n" "danger"
    return 0;
  fi
}

# Return true if we pass in an IPv4 pattern.
valid_ip() {
  rx="([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])"
  if [[ $1 =~ ^$rx\.$rx\.$rx\.$rx$ ]]; then
    if [[ $WITH_CNI == true ]]; then
      #valid CIDR
      if [[ $2 =~ ^$rx\.$rx\.$rx\.$rx\/$rx$ ]]; then
        #192.168
        if [[ "$1" == *192.168.*.* ]]; then
          if [[ "$2" == *192.168.*.* ]]; then
            printstyle "The host ip and private ip cannot be in the same range. \n" "danger"
            return 0
          fi
        #172.16
        elif [[ "$1" == *172.16.*.* ]]; then
          if [[ "$2" == *172.16.*.* ]]; then
            printstyle "The host ip and private ip cannot be in the same range. \n" "danger"
            return 0
          fi
        #10.0
        elif [[ "$1" == *10.0.*.* ]]; then
          if [[ "$2" == *10.0.*.* ]]; then
            printstyle "The host ip and private ip cannot be in the same range. \n" "danger"
            return 0
          fi
        fi
        # check a private ip range
        if [[ "$2" == *192.168.*.*/* ]] || [[ "$2" == *172.16.*.*/* ]] || [[ "$2" == *10.0.*.*/* ]]; then
          return 1
        else
          printstyle "Incorrect private IP address format  : $2 \n" "danger"
          return 0
        fi
      else
        printstyle "Incorrect IP address format  : $2 \n" "danger"
        return 0
      fi
      return 1
    fi
    return 1
  else
    printstyle "Incorrect IP address format  : $1 \n" "danger"
    return 0
  fi
}

valid_version() {
  for item in ${SUPPORT_VERSION_LIST[@]}; do
    if [[ "$1" == "${item}" ]]; then
      return 1
    fi
  done
  printstyle "Invalid or unsupported version. \n" "danger"
  printstyle "List of supported versions:"
  echo "${SUPPORT_VERSION_LIST[@]}"
  return 0
}

valid_cidr() {
  rx="([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])"

  if [[ $1 =~ ^$rx\.$rx\.$rx\.$rx$ ]]; then
    if [[ $WITH_CNI == true ]]; then
      return 1
    elif [[ "$1" == *192.168.*.* ]]; then
      printstyle "IP addresses in 192.168.0.0/16 range cannot be used. if you want it, don't use --c/--cni flag \n" "danger"
      return 0
    fi
    return 1
  else
    printstyle "Incorrect IP address format  : $1 \n" "danger"
    return 0
  fi
}

lineprint() {
  if [[ -z "$COLUMNS" ]]; then
    printf "%70s\n" | tr " " "="
  else
    printf "%${COLUMNS}s\n" | tr " " "="
  fi
}

# bool function to test if the user is root or not
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  printstyle "Please run as root \n" "danger"
  exit 1
fi

SUPPORT_VERSION_LIST=("1.24.15" "1.24.16" "1.24.17" "1.25.0" "1.25.1" "1.25.2" "1.25.3" "1.25.4" "1.25.5" "1.25.6" "1.25.7" "1.25.8" "1.25.9" "1.25.10" "1.25.11" "1.25.12" "1.25.13" "1.26.0" "1.26.1" "1.26.2" "1.26.3" "1.26.4" "1.26.5" "1.26.6" "1.26.7" "1.26.8" "1.27.0" "1.27.1" "1.27.2" "1.27.3" "1.27.4" "1.27.5")

VALID_PARAM2=false
VALID_WORKER=false
VALID_MASTER=false
OPT_REGULAR_USER=false
VALID_USERNAME=false
VALID_PWD=false
WITH_CNI=false
CONTAINER_TYPE="docker"
USED_CONTAINERD=false
CRI_SOCKET=""
K8S_VERSION=""

while (( "$#" )); do
  case "$1" in
    -i|--ip)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        HOST_IP=$2
        VALID_PARAM2=true
        shift 2
      else
        printstyle "Error: Argument for $1 is missing \n" "danger"
        exit 1
      fi
      ;;
    -r|--regularuser)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        REGULAR_USER_PATH=$2
        OPT_REGULAR_USER=true
        shift 2
      else
        printstyle "Error: Argument for $1 is missing \n" "danger"
        exit 1
      fi
      ;;
    -m|--master)
        VALID_MASTER=true
        shift
      ;;
    -w|--worker)
        VALID_WORKER=true
        shift
      ;;
    -c|--cni)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        WITH_CNI=true
        CNI_CIDR=$2
        shift 2
      else
        printstyle "Error: Argument for $1 is missing \n" "danger"
        exit 1
      fi
      ;;
    -u|--username)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        MASTER_USERNAME=$2
        VALID_USERNAME=true
        shift 2
      else
        printstyle "Error: Argument for $1 is missing \n" "danger"
        exit 1
      fi
      ;;
    -p|--password)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        MASTER_PWD=$2
        VALID_PWD=true
        shift 2
      else
        printstyle "Error: Argument for $1 is missing \n" "danger"
        exit 1
      fi
      ;;
    -ct|--containertype)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        CONTAINER_TYPE=$2
        shift 2
      else
        printstyle "Error: Argument for $1 is missing \n" "danger"
        exit 1
      fi
      ;;
    -v|--version)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        K8S_VERSION=$2
        shift 2
      else
        printstyle "Error: Argument for $1 is missing \n" "danger"
        exit 1
      fi
      ;;
    -h|--help)
      printstyle "Usage:  $0 [options] <value> \n"
      printstyle "        -c  | --cni <CIDR>                                 Use this flag to apply CNI with calico when initializing a master node. (When using this flag, the parameter must be a private IP range that does not overlap with the Host IP. \nex. 172.16.0.0/12)\n"
      printstyle "                                                           You can use one of three types of private IP range.\n"
      printstyle "                                                           10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16\n"
      printstyle "                                                           e.g. Host IP: 192.168.x.x then, cidr: 172.16.0.0/12\n"
      printstyle "        -ct | --containertype <Container Runtime>          Set to specify for a container runtime type. \n"
      printstyle "                                                           if you not use this option, it will default to docker(cri-docker) runtime. \n"
      printstyle "                                                           You can use one of two types of container runtime:.\n"
      printstyle "                                                           docker, containerd\n"
      printstyle "                                                           e.g. -ct containerd\n"
      printstyle "        -h  | --help                                       Use this flag for more detailed help \n"
      printstyle "        -i  | --ip <Host IP>                               host-private-ip(master node) configuration for kubernetes. \n"
      printstyle "        -kv | --k8sversion                                 Shows a list of supported Kubernetes versions. \n"
      printstyle "        -m  | --master                                     Set to initialize this node a master node. \n"
      printstyle "        -p  | --password <Password>                        Use password(master node) to access the master for a token copy when initialing worker node. \n"
      printstyle "        -r  | --regularuser <HOME_PATH_OF_REGULAR_USER>    Allow regular users to access kubernetes. \n"
      printstyle "        -u  | --username <Username>                        Use username(master node) to access the master for a token copy when initialing worker node. \n"
      printstyle "        -v  | --version <k8s Version>                      Select your version of Kubernetes to install. The default is version 1.24.15. \n"
      printstyle "                                                           Parameters must be in x.y.z format, and available versions are 1.24.15 ~ 1.27.5 \n"
      printstyle "                                                           Kubernetes versions can be found at https://github.com/kubernetes/kubernetes/releases. \n"
      printstyle "                                                           or using the flag -kv | --k8sversion option. \n"
      printstyle "                                                           We are not responsible for compatibility with RC(Release Candidate) or beta versions. \n"
      printstyle "                                                           e.g. -v 1.25.0 \n"
      printstyle "        -w  | --worker                                     Set to initialize this node as a worker node. \n"
      exit 0
      ;;
    -kv|--k8sversion)
      printstyle "List of supported k8s versions: \n"
      echo "${SUPPORT_VERSION_LIST[@]}"
      exit 0
      ;;
    -*|--*) # unsupported flags
      printstyle "Error: Unsupported flag: $1 \n" "danger"
      printstyle "$0 -h for help message \n" "danger"
      exit 1
      ;;
    # *)
    #   printstyle "Error: Arguments with not proper flag: $1 \n" "danger"
    #   printstyle "$0 -h for help message \n" "danger"
    #   exit 1
    #   ;;
  esac
done

if [[ $VALID_MASTER == true ]] && [[ $VALID_WORKER == true ]]; then
  printstyle "Both options(-m and -w) cannot be used together.\n" "danger"
  exit 1
elif [[ $VALID_PARAM2 == false ]]; then
  if [[ $VALID_MASTER == true ]] || [[ $VALID_WORKER == true ]]; then
    printstyle "Error: Missing flag and argument: -i/--ip \n" "danger"
    printstyle "$0 -h for help message \n" "danger"
    exit 1
  fi
elif [[ $VALID_WORKER == true ]] && [[ $VALID_USERNAME == false ]]; then
  printstyle "Error: Missing flag and argument: -u/--username or -p/--password \n" "danger"
  exit 1
elif [[ $VALID_WORKER == true ]] && [[ $VALID_PWD == false ]]; then
  printstyle "Error: Missing flag and argument: -u/--username or -p/--password \n" "danger"
  exit 1
fi
# check Host-IP
if [[ $VALID_MASTER == true ]] || [[ $VALID_WORKER == true ]]; then
  if [[ -z "$HOST_IP" ]]; then
    printstyle "No IP argument supplied. \n" "danger"
    printstyle "Please run with IP address like x.x.x.x \n" "danger"
  fi
  if [[ $WITH_CNI == true ]]; then
    if valid_ip "$HOST_IP" "$CNI_CIDR" ; then
      exit 1
    fi
  elif valid_ip "$HOST_IP" ; then
    exit 1
  fi
fi

# check container name
if valid_container_name "$CONTAINER_TYPE" ; then
  exit 1
fi

# check k8s version
if valid_version "$K8S_VERSION" ; then
  exit 1
fi

HOME_PATH=$HOME
printstyle "Home path is $HOME_PATH \n" "info"

# requirement package list
if ! which wget > /dev/null; then
  printstyle 'Cannot find wget, install with: \n' "danger"
  printstyle '           apt-get install wget \n'
  exit 1
fi

if ! which gpg > /dev/null; then
  printstyle 'Cannot find GnUPG, install with: \n' "danger"
  printstyle '           apt-get install gnupg \n'
  exit 1
fi

if ! which git > /dev/null; then
  printstyle 'Cannot find git, install with: \n' "danger"
  printstyle            'apt-get intsall git \n'
  exit 1
fi

cd $HOME_PATH

# disabled swap memory and firewall
lineprint
printstyle "swap off memory ... \n" "info"
lineprint
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sleep 3
printstyle 'Success! \n \n' "success"

lineprint
printstyle "inactive ufw ...\n" "info"
lineprint
ufw disable
sleep 3
printstyle "OK! \n \n" "success"

if ! [[ "$PWD" = "$HOME_PATH" ]]; then 
  cd $HOME_PATH
fi

# Uninstalling conflicting packages
lineprint
printstyle 'Uninstalling all conflicting packages ... \n' 'info'
lineprint
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do apt-get remove $pkg; done
printstyle 'Success! \n \n' 'success'

# update and install packages needed to use the Kubernetes
lineprint
printstyle 'Update and install packages needed to use Kubernetes ... \n' 'info'
lineprint
apt-get update
apt-get install -y apt-transport-https ca-certificates curl sshpass
printstyle 'Success! \n \n' 'success'

# Download the GPG key for docker
lineprint
printstyle "Downloading the GPG key from docker repository ... \n" 'info'
lineprint
wget -O - https://download.docker.com/linux/ubuntu/gpg > ./docker.key
gpg --no-default-keyring --keyring ./docker.gpg --import ./docker.key
gpg --no-default-keyring --keyring ./docker.gpg --export > ./docker-archive-keyring.gpg
mv ./docker-archive-keyring.gpg /etc/apt/trusted.gpg.d/
printstyle 'Success! \n \n' 'success'

if [[ $USED_CONTAINERD == true ]]; then
  lineprint
  printstyle 'Configuring containerd... \n' 'info'
  lineprint
  echo | add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  apt-get update
  apt-get install -y containerd.io
  if [[ $? -ne 0 ]]; then
      printstyle 'Fail to install containerd.io ... \n' 'warning'
      exit 1
  fi
  mkdir -p /etc/containerd
  containerd config default | tee /etc/containerd/config.toml
  sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
  systemctl restart containerd
  sleep 5
  echo
else
  # Add the docker repository
  lineprint
  printstyle "Installing docker and adding docker repository... \n" 'info'
  lineprint
  echo | add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  apt-get update
  DOCKERVERSION=$(apt-cache madison docker-ce | awk '{ print $3 }' | head -1)
  apt-get install -y docker-ce=$DOCKERVERSION docker-ce-cli=$DOCKERVERSION containerd.io docker-buildx-plugin docker-compose-plugin
  apt-mark hold docker-ce docker-ce-cli
  groupadd docker
  usermod -aG docker $USER
  printstyle 'Success! \n \n' 'success'

  # Installing go lang
  lineprint
  printstyle "Installing Golang ... \n" 'info'
  lineprint
  wget https://go.dev/dl/go1.20.5.linux-amd64.tar.gz
  rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.5.linux-amd64.tar.gz
  echo 'export PATH=$PATH:/usr/local/go/bin' >>${HOME_PATH}/.profile
  echo 'export GOPATH=$HOME/go' >>${HOME_PATH}/.profile
  source ${HOME_PATH}/.profile
  mkdir -p $GOPATH
  go version
  sleep 3
  printstyle 'Success! \n \n' 'success'

  # clone the repository
  lineprint
  printstyle "Cloning cri-dockerd repository ... \n" 'info'
  lineprint
  git clone https://github.com/Mirantis/cri-dockerd.git
  printstyle 'Success! \n \n' 'success'

  # Install Container runtime (cri-dockerd)
  cd cri-dockerd

  if ! [[ "$PWD" = "${HOME_PATH}/cri-dockerd" ]]; then 
    cd $HOME_PATH
  fi

  lineprint
  printstyle "Install cri-dockerd ... (It will take about 10 ~ 30 minutes) \n" 'info'
  lineprint
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
  printstyle 'Success! \n \n' 'success'
fi



# Add the GPG key for kubernetes
lineprint
printstyle "Add THE GPG key for kubernetes ... \n" 'info'
lineprint
cd $HOME_PATH
if ! [[ "$PWD" = "$HOME_PATH" ]]; then 
  cd $HOME_PATH
fi

VERSION_SPLIT=($(echo $K8S_VERSION | tr "." "\n"))
K8S_MAJOR_VERSION="${VERSION_SPLIT[0]}.${VERSION_SPLIT[1]}"
# check z version in x.y.z
K8S_PACKAGE_VERSION=""
if [[ "${VERSION_SPLIT[2]}" == "0" ]]; then
    K8S_PACKAGE_VERSION="${K8S_VERSION}-2.1"
else
    K8S_PACKAGE_VERSION="${K8S_VERSION}-1.1"
fi

mkdir -m 755 /etc/apt/keyrings
# temp: curl -fsLo /usr/share/keyrings/kubernetes-archive-keyring.gpg http://printstyle-bio.cn:8888/kubernetes-archive-keyring.gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$K8S_MAJOR_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
printstyle 'Success! \n \n' 'success'

# Add the kubernetes repository
lineprint
printstyle "Apply kubernetes repository ... \n" 'info'
lineprint
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v'"$K8S_MAJOR_VERSION"'/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
sleep 2
printstyle '\nSuccess! \n \n' 'success'

# Update apt-get
apt-get update
if [[ $? -ne 0 ]]; then
  apt-get update >> apt-get-update.log
  printstyle 'Fail... \n' 'warning'
  printstyle 'retry... \n'
  grep -o 'NO_PUBKEY.*' apt-get-update.log | while read -r _ key; do 
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key"
    break
  done
  rm apt-get-update.log
  
  apt-get update >> apt-get-update.log

  if [[ $? -ne 0 ]]; then
    printstyle 'Fail... \n' 'warning'
    printstyle 'retry... \n'
    curl -fsSLo /etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
    printstyle 'cannot update for kubernetes repository! \n \n' 'warning'
    cat apt-get-update.log
    rm apt-get-update.log
    exit 1
  fi
  apt-get update
  printstyle 'Success! \n \n' 'success'
fi


# Install Kubernetes packages.
lineprint
printstyle "Installing kubernetes components ... \n" 'info'
lineprint
apt-get install -y kubelet=$K8S_PACKAGE_VERSION kubeadm=$K8S_PACKAGE_VERSION kubectl=$K8S_PACKAGE_VERSION
## The exit status of the last command run is 
## saved automatically in the special variable $?.
## Therefore, testing if its value is 0, is testing
## whether the last command ran correctly.
if [[ $? > 0 ]]; then
  printstyle 'Fail... \n' 'warning'
  rm /var/lib/apt/lists/lock
  rm /var/cache/apt/archives/lock
  rm /var/lib/dpkg/lock*
  apt-get install -y kubelet=$K8S_PACKAGE_VERSION kubeadm=$K8S_PACKAGE_VERSION kubectl=$K8S_PACKAGE_VERSION
  if [[ $? > 0 ]]; then
    outputerr = 
    printstyle "apt-get install -y kubelet=$K8S_PACKAGE_VERSION kubeadm=$K8S_PACKAGE_VERSION kubectl=$K8S_PACKAGE_VERSION \n Fail... \n Please fixed apt-get\n" 'warning'
    exit
  fi

else
    printstyle '\nSuccess! \n \n' 'success'
fi
lineprint
printstyle 'Holding kubelete kubeadm kubectl... \n' 'info'
lineprint
apt-mark hold kubelet kubeadm kubectl
printstyle '\nSuccess! \n \n' 'success'

# Enable the iptables bridge
lineprint
printstyle "Enabling the iptables bridge & sysctl params required by setup, params persist across reboots ... \n" 'info'
lineprint
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
sleep 5

printstyle '\nOK! \n \n' 'success'

# init master node
if [[ $VALID_MASTER == true ]]; then
  lineprint
  printstyle "Generating cluster... \n" 'info'
  lineprint

  kubeadm init --kubernetes-version=v$K8S_VERSION --apiserver-advertise-address=$HOST_IP --pod-network-cidr=$CNI_CIDR --cri-socket=$CRI_SOCKET
  
  printstyle '\nSuccess generate cluster! \n \n' 'success'

  lineprint
  printstyle "Generating config... \n" 'info'
  lineprint

  mkdir -p $HOME_PATH/.kube
  cp -i /etc/kubernetes/admin.conf $HOME_PATH/.kube/config
  chown $(id -u):$(id -g) $HOME_PATH/.kube/config

  if [[ $OPT_REGULAR_USER == true ]]; then
    mkdir -p $REGULAR_USER_PATH/.kube
    cp -i /etc/kubernetes/admin.conf $REGULAR_USER_PATH/.kube/config
    chown $(id -u):$(id -g) $REGULAR_USER_PATH/.kube/config
  fi
  printstyle 'Success generate config! \n \n' 'success'
  lineprint
  printstyle "Generating token... \n" 'info'
  lineprint

  KTOKEN=$(kubeadm token create --print-join-command)
  
  if [[ -n "$KTOKEN" ]]; then
    printstyle "Success Create Token \n \n" 'success'
  else
    printstyle "Failed Create Token \n" 'danger'
    exit 1
  fi

  printstyle 'Token is : ' 'info'
  echo "$KTOKEN"
  echo -n "$KTOKEN" > /tmp/k8stkfile.kstk
  echo " --cri-socket=unix:///var/run/cri-dockerd.sock" >> /tmp/k8stkfile.kstk
  chmod 755 /tmp/k8stkfile.kstk
  printstyle 'Success! \n \n' 'success'
  lineprint
  if [[ $WITH_CNI == true ]]; then
    printstyle "Installing cni with calico... \n" 'info'
    lineprint
    sleep 120
    mkdir $HOME_PATH/cni
    cd $HOME_PATH/cni
    curl -sSLO https://raw.githubusercontent.com/kdgyun/KubernetesAutoDeployment/main/cni/prefix.yaml
    curl -sSLO https://raw.githubusercontent.com/kdgyun/KubernetesAutoDeployment/main/cni/suffix.yaml
    cd $HOME_PATH
    echo $(cat $HOME_PATH/cni/prefix.yaml>>$HOME_PATH/calico.yaml)
    echo -e "\n            - name: CALICO_IPV4POOL_CIDR\n              value: "$CNI_CIDR"">>$HOME_PATH/calico.yaml
    echo $(cat $HOME_PATH/cni/suffix.yaml>>$HOME_PATH/calico.yaml)
    kubectl apply -f $HOME_PATH/calico.yaml
    rm -rf $HOME_PATH/cni
    printstyle "Success! \n" 'success'
  fi
fi

if [[ $VALID_WORKER == true ]]; then
  lineprint
  printstyle "Joining cluster... \n" 'info'
  lineprint
  sshpass -p $MASTER_PWD rsync -e "ssh -o StrictHostKeyChecking=no" --progress $MASTER_USERNAME@$HOST_IP:/tmp/k8stkfile.kstk /tmp/k8stkfile.kstk
  TOKENCOMM=$(</tmp/k8stkfile.kstk)
  printstyle "excute command: $TOKENCOMM ... \n" 'info'
  eval "$TOKENCOMM"
  if [[ -n "$TOKENCOMM" ]]; then
    printstyle "Success! \n" 'success'
  else
    printstyle "Failed! \n" 'danger'
  fi
fi