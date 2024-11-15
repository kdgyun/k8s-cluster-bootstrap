 **[한글 문서](./README.md)** | **English Document**

<br />
  
   
![](https://img.shields.io/github/v/release/kdgyun/KubernetesAutoDeployment?style=flat-square)
![](https://img.shields.io/github/issues/kdgyun/KubernetesAutoDeployment?color=red&style=flat-square)
![](https://img.shields.io/github/issues-closed/kdgyun/KubernetesAutoDeployment?style=flat-square)
![](https://img.shields.io/github/license/kdgyun/KubernetesAutoDeployment?style=flat-square)
![](https://img.shields.io/github/languages/code-size/kdgyun/KubernetesAutoDeployment?style=flat-square)
![](https://img.shields.io/static/v1?label=Ubuntu&message=<=22.04.2_LTS(Jammy_Jellyfish)&color=green&style=flat-square&logo=ubuntu)
![](https://img.shields.io/static/v1?label=Ubuntu&message=>=v18.04.06_LTS(Bionic_Beaver)&color=green&style=flat-square&logo=ubuntu)
![](https://img.shields.io/static/v1?label=Kubernetes&message=>=v1.24.15&color=green&style=flat-square&logo=kubernetes)
![](https://img.shields.io/static/v1?label=Kubernetes&message=<=v1.31.2&color=green&style=flat-square&logo=kubernetes)
![](https://img.shields.io/static/v1?label=cri-socket&message=cri-dockerd.v0.0.3&color=green&style=flat-square&logo=docker)
![](https://img.shields.io/static/v1?label=docker&message=v24.0.15&color=green&style=flat-square&logo=docker)
![](https://img.shields.io/static/v1?label=go&message=v1.20.5&color=green&style=flat-square&logo=go)



<br />

# k8s-cluster-bootstrap

#### 🔨 An easy and ready-to-go bootstrap for k8s installation and automatic cluster deployment!

<br />
   
## Requirements   

- Ubuntu (or ubuntu server) version between 18.04 (inclusive) and 22.04 (inclusive) recommended.
- Nodes (both master and workers) are to be in the same subnet. **For calico autodeployment to work** the Master node's IP(Host IP) must **not be within the same CIDR**.
- If accessing via ssh, use username/password authentication and not pem.
- The script automatically opens some ports (such as 6443), but ports may need to be manually opened in case of firewalls or company policies.
  ([ports required to be open for k8s installation](https://kubernetes.io/docs/reference/networking/ports-and-protocols/))



<br />
<br />

## **Usage**


### 1. Bootstrap download

From the home directory, run `curl -sSLO http://raw.githubusercontent.com/kdgyun/k8s-cluster-bootstrap/main/k8s-cluster-bootstrap.sh` or download from github [**latest release version**](https://github.com/kdgyun/k8s-cluster-bootstrap/releases/) and run k8s-cluster-bootstrap.sh.

<br />   

### 2. File Run Permission

Grant `k8s-cluster-bootstrap.sh` the following permission:

```bash
chmod +x k8s-cluster-bootstrap.sh
```

<br />   

### 3. Execution

Run `k8s-cluster-bootstrap.sh` with sudo.

```bash
sudo ./k8s-cluster-bootstrap.sh [options] <value>
```

The arguments for [options] are explained below.

<br />   

<br />   

## Options

<br />

The following shows the available options to run this bootstrap.

| Option(Flag) | Values | Description, example | Remarks |
| --- | --- | --- | --- |
| ```-c / --cni``` | CIDR | Installs cni(with calico) during master node installation. | To utilize this option, the master's IP(Host IP) cannot overlap with calico's CIDR. Please utilize one of the following CIDR: ```10.0.0.0/8```, ```172.16.0.0/12```, ```192.168.0.0/16```. |
| ```-ct / --containertype``` | Container Runtime | Specify the type of container runtime k8s will use. If empty, it will default to ```docker(cri-dockerd)``` | For **cri-dockerd** write ```docker``` , <br /> for **containerd** write ```containerd``` as the parameter for this option. |
| ```-h / --help``` |  | Display all options and their respective descriptions. |  |
| ```-i / --ip``` | Master's (Host) IP | Declare IP for master node (e.g, 10.0.0.1). <br /> In case of deploying k8s in a cloud (e.g, aws, gcp …) declare an IP with the scope of a private IP, not the public IP. |  |
| ```-kv / --k8sversion``` |  | Displays all versions of k8s this bootstrap can install |  |
| ```-m / --master``` |  | Use this option to install a master ```-m```  | The flag ```-i/--ip``` is a must if this option is utilized. |
| ```-ms / --metricserver``` |  | To install the metrics-server for Kubernetes, use the `-ms` flag.  | It can only be installed when configuring a master node, so the `-m/--master` flag is also required. |
| ```-p / --password``` | Master(Host) node password | Required for ssh login using a password. <br /> It is done so the worker node can access the master during installation to obtain the join token. Both master and worker must be in the same subnet.  | The flag ```-u/--username``` is a must if this option is utilized. |
| ```-r / --regularuser``` <br /> **(\*beta)** | HOME_PATH of regular user | This bootstrap is executed with sudo permission, thus this option is used to allow regular users (such as the user `ubuntu` in ubuntu servers) to also use k8s. <br /> run this option as ```-r /home/username```. Crucial that HOME_PATH is the same as **the regular user's home directory($HOME)** | Not a must option. Utilized when initializing a master node with ```-m```. |
| ```-u / --username``` | Master(Host) node username | ```username``` for ssh login. <br /> Set so a newly created worker node within the same subnet as the master node can fetch the join token from the master node.  | The floag ```-p/--password``` is a must if this option is utilized.  |
| ```-v / --version``` | k8s version | Declare k8s version to install. <br /> Supports k8s version from ```1.24.15``` to ```1.31.2``` and more details can be checked using the ```-kv``` or ```--k8sversion``` option. | The parameters for this options are to be written as ```x.y.z```. <br /> Not using this option will default k8s version to ```1.24.15``` and does not support RC nor beta versions since they are not stable versions. |
| ```-w / --worker``` |  | Used to specify worker node installation. | the following 3 options are required: ```-i/--ip``` , ```-u/--username```, ```-p/-password```. |

<br />
<br />

Executing this bootstrap with **no** options will only install the packages for k8s (no auto deployment)

In the case that only the packages are install, you can still use the ```kubeadm init``` command to manually deploy nodes.

example for installing k8s and deploying a **master** node:

```bash
sudo ./k8s-cluster-bootstrap.sh -m -c 192.168.0.0/16 -i 10.0.0.1 -ct containerd -v 1.25.0
```
<br />   

example for installing k8s and deploying a **worker** node:

```bash
sudo ./k8s-cluster-bootstrap.sh -w -i 10.0.0.1 -u username -p pwd123! -ct containerd -v 1.25.0
```

<br />

## Contribution guidelines
**If you want to contribute to this Repo, be sure to review the
[contribution guidelines](.github/CONTRIBUTING.md).**
