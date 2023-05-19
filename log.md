./install-k8s-1.24-for-ubuntu18-server.sh: line 24: cd: $HOME: No such file or directory
swap off memory ...OK!
inactive ufw ...Firewall stopped and disabled on system startup
OK!
Download the GPG key for docker ...--2023-05-19 09:49:28--  https://download.docker.com/linux/ubuntu/gpg
Resolving download.docker.com (download.docker.com)... 99.86.207.54, 99.86.207.27, 99.86.207.93, ...
Connecting to download.docker.com (download.docker.com)|99.86.207.54|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 3817 (3.7K) [binary/octet-stream]
Saving to: ‘STDOUT’

-                                                           100%[=========================================================================================================================================>]   3.73K  --.-KB/s    in 0s      

2023-05-19 09:49:28 (190 MB/s) - written to stdout [3817/3817]

gpg: WARNING: unsafe ownership on homedir '/home/test/.gnupg'
gpg: keybox './docker.gpg' created
gpg: /home/test/.gnupg/trustdb.gpg: trustdb created
gpg: key 8D81803C0EBFCD88: public key "Docker Release (CE deb) <docker@docker.com>" imported
gpg: Total number processed: 1
gpg:               imported: 1
gpg: WARNING: unsafe ownership on homedir '/home/test/.gnupg'
OK!
Get:1 https://download.docker.com/linux/ubuntu bionic InRelease [64.4 kB]
Get:2 https://download.docker.com/linux/ubuntu bionic/stable amd64 Packages [37.9 kB]
Hit:3 http://kr.archive.ubuntu.com/ubuntu bionic InRelease                               
Get:4 http://kr.archive.ubuntu.com/ubuntu bionic-updates InRelease [88.7 kB]
Get:5 http://kr.archive.ubuntu.com/ubuntu bionic-backports InRelease [83.3 kB]
Get:6 http://kr.archive.ubuntu.com/ubuntu bionic-security InRelease [88.7 kB]
Fetched 363 kB in 2s (197 kB/s)   
Reading package lists... Done
OK!
Add the docker repository ...Cloning into 'cri-dockerd'...
remote: Enumerating objects: 16653, done.
remote: Counting objects: 100% (16653/16653), done.
remote: Compressing objects: 100% (7034/7034), done.
remote: Total 16653 (delta 8156), reused 16527 (delta 8120), pack-reused 0
Receiving objects: 100% (16653/16653), 36.34 MiB | 10.30 MiB/s, done.
Resolving deltas: 100% (8156/8156), done.
OK!
Login as root and run below commands ...--2023-05-19 09:49:39--  https://storage.googleapis.com/golang/getgo/installer_linux
Resolving storage.googleapis.com (storage.googleapis.com)... 142.250.206.240, 172.217.161.208, 142.250.76.144, ...
Connecting to storage.googleapis.com (storage.googleapis.com)|142.250.206.240|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 5179246 (4.9M) [application/octet-stream]
Saving to: ‘installer_linux’

installer_linux                                             100%[=========================================================================================================================================>]   4.94M  8.32MB/s    in 0.6s    

2023-05-19 09:49:40 (8.32 MB/s) - ‘installer_linux’ saved [5179246/5179246]

Welcome to the Go installer!
Downloading Go version go1.20.4 to /home/test/.go
This may take a bit of time...
Downloaded!
Setting up GOPATH
GOPATH has been set up!

One more thing! Run `source /home/test/.bash_profile` to persist the
new environment variables to your current session, or open a
new shell prompt.
OK!
./install-k8s-1.24-for-ubuntu18-server.sh: line 75: cd: $HOME: No such file or directory
Install the cri-dockerd ... (It will takes about 10~30 minutes)Created symlink /etc/systemd/system/multi-user.target.wants/cri-docker.service → /etc/systemd/system/cri-docker.service.
Created symlink /etc/systemd/system/sockets.target.wants/cri-docker.socket → /etc/systemd/system/cri-docker.socket.
OK!
Add the GPG key for kubernetes ...OK!
deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main
OK!
Hit:1 https://download.docker.com/linux/ubuntu bionic InRelease
Hit:2 http://kr.archive.ubuntu.com/ubuntu bionic InRelease                                                          
Hit:4 http://kr.archive.ubuntu.com/ubuntu bionic-updates InRelease         
Hit:5 http://kr.archive.ubuntu.com/ubuntu bionic-backports InRelease                                          
Hit:6 http://kr.archive.ubuntu.com/ubuntu bionic-security InRelease                
Get:3 https://packages.cloud.google.com/apt kubernetes-xenial InRelease [8993 B]
Err:3 https://packages.cloud.google.com/apt kubernetes-xenial InRelease
  The following signatures couldn't be verified because the public key is not available: NO_PUBKEY B53DC80D13EDEF05
Reading package lists... Done
W: GPG error: https://packages.cloud.google.com/apt kubernetes-xenial InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY B53DC80D13EDEF05
E: The repository 'https://apt.kubernetes.io kubernetes-xenial InRelease' is not signed.
N: Updating from such a repository can't be done securely, and is therefore disabled by default.
N: See apt-secure(8) manpage for repository creation and user configuration details.
Reading package lists... Doneents ...
Building dependency tree       
Reading state information... Done

No apt package "kubeadm", but there is a snap with that name.
Try "snap install kubeadm"


No apt package "kubectl", but there is a snap with that name.
Try "snap install kubectl"


No apt package "kubelet", but there is a snap with that name.
Try "snap install kubelet"

E: Unable to locate package kubelet
E: Unable to locate package kubeadm
E: Unable to locate package kubectl
docker-ce set on hold.
E: Unable to locate package kubelet
E: Unable to locate package kubeadm
E: Unable to locate package kubectl
OK!
Enable the iptables bridge & sysctl params required by setup, params persist across reboots ...overlay
br_netfilter
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
* Applying /etc/sysctl.d/10-console-messages.conf ...
kernel.printk = 4 4 1 7
* Applying /etc/sysctl.d/10-ipv6-privacy.conf ...
net.ipv6.conf.all.use_tempaddr = 2
net.ipv6.conf.default.use_tempaddr = 2
* Applying /etc/sysctl.d/10-kernel-hardening.conf ...
kernel.kptr_restrict = 1
* Applying /etc/sysctl.d/10-link-restrictions.conf ...
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
* Applying /etc/sysctl.d/10-lxd-inotify.conf ...
fs.inotify.max_user_instances = 1024
* Applying /etc/sysctl.d/10-magic-sysrq.conf ...
kernel.sysrq = 176
* Applying /etc/sysctl.d/10-network-security.conf ...
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.tcp_syncookies = 1
* Applying /etc/sysctl.d/10-ptrace.conf ...
kernel.yama.ptrace_scope = 1
* Applying /etc/sysctl.d/10-zeropage.conf ...
vm.mmap_min_addr = 65536
* Applying /usr/lib/sysctl.d/50-default.conf ...
net.ipv4.conf.all.promote_secondaries = 1
net.core.default_qdisc = fq_codel
* Applying /etc/sysctl.d/99-sysctl.conf ...
* Applying /etc/sysctl.d/k8s.conf ...
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
* Applying /etc/sysctl.conf ...
OK!
