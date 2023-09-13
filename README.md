 **한글 문서** | **[English Document](./README-en.md)**

<br />
  
   
![](https://img.shields.io/github/v/release/kdgyun/KubernetesAutoDeployment?style=flat-square)
![](https://img.shields.io/github/issues/kdgyun/KubernetesAutoDeployment?color=red&style=flat-square)
![](https://img.shields.io/github/issues-closed/kdgyun/KubernetesAutoDeployment?style=flat-square)
![](https://img.shields.io/github/license/kdgyun/KubernetesAutoDeployment?style=flat-square)
![](https://img.shields.io/github/languages/code-size/kdgyun/KubernetesAutoDeployment?style=flat-square)
![](https://img.shields.io/static/v1?label=Ubuntu&message=<=22.04.2_LTS(Jammy_Jellyfish)&color=green&style=flat-square&logo=ubuntu)
![](https://img.shields.io/static/v1?label=Ubuntu&message=>=v18.04.06_LTS(Bionic_Beaver)&color=green&style=flat-square&logo=ubuntu)
![](https://img.shields.io/static/v1?label=Kubernetes&message=>=v1.24.15&color=green&style=flat-square&logo=kubernetes)
![](https://img.shields.io/static/v1?label=Kubernetes&message=<=v1.27.5&color=green&style=flat-square&logo=kubernetes)
![](https://img.shields.io/static/v1?label=cri-socket&message=cri-dockerd.v0.0.3&color=green&style=flat-square&logo=docker)
![](https://img.shields.io/static/v1?label=docker&message=v24.0.15&color=green&style=flat-square&logo=docker)
![](https://img.shields.io/static/v1?label=go&message=v1.20.5&color=green&style=flat-square&logo=go)



<br />

# k8s-cluster-bootstrap


#### 🔨 k8s 설치 및 클러스터 구축 자동화를 위한 easy 한 부트스트랩
<br />
   
## Requirements   

- Ubuntu 18.04 (or Ubuntu Server 18.04) 이상, Ubuntu 22.04 (or Ubuntu Server 22.04) 이하 - 우분투 서버 권장
- 동일한 subnet 안에 있어야 함. 단, **calico까지 자동으로 배포할 시** Master node IP(HOST IP)가 **CIDR 내에 있으면 안됨**
- ssh 접속시 pem 키가 아닌 username과 password로 접속이 가능해야 함
- 스크립트 내 사용포트에 대해 open을 하나, 만약 별도의 자체 방화벽이 있을 경우 port 개방이 필요함
  ([필수 개방 포트 링크](https://v1-24.docs.kubernetes.io/docs/reference/ports-and-protocols/))



<br />
<br />

## **Usage**


### 1. 파일 다운로드

홈 디렉토리에서 `curl -sSLO http://raw.githubusercontent.com/kdgyun/KubernetesAutoDeployment/main/k8s-cluster-bootstrap.sh` 혹은 깃허브의 [**latest release 버전**](https://github.com/kdgyun/KubernetesAutoDeployment/releases/)을 다운로드하여 k8s-cluster-bootstrap.sh을 받기

<br />   

### 2. 파일 실행 권한 부여

k8s-cluster-bootstrap.sh 파일의 실행 권한 부여

```bash
chmod +x k8s-cluster-bootstrap.sh
```

<br />   

### 3. 실행

sudo 권한으로 `k8s-cluster-bootstrap.sh`  파일 실행

```bash
sudo ./k8s-cluster-bootstrap.sh [options] <value>
```


옵션에 대한 상세 설명은 아래에…

<br />   

<br />   

## Options

<br />

다음은 스크립트에서 제공하고 있는 옵션입니다.

| Option(Flag) | Values | Description, example | Remarks |
| --- | --- | --- | --- |
| ```-c / --cni``` | CIDR | 마스터 노드 생성시 cni(with calico)도 함께 설치합니다. | 해당 옵션을 사용할시, master node IP(Host IP)랑 대역이 겹치면 안되며, ```10.0.0.0/8```, ```172.16.0.0/12```, ```192.168.0.0/16``` 중 하나를 선택하여 입력하시면 됩니다. |
| ```-ct / --containertype``` | Container Runtime | container runtime 타입을 지정하고자 하는 경우 사용되는 옵션이며 지정하지 않을 경우 기본 값은 ```docker(cri-docker)``` 입니다. | 해당 옵션을 사용할시 **cri-docker** 의 경우 ```docker``` , <br /> **containerd** 의 경우 ```containerd``` 을 파라미터로 설정하여 사용하고자 하는 컨테이너 런타임을 입력하시면 됩니다. |
| ```-h / --help``` |  | 옵션 및 설명을 볼 수 있습니다. |  |
| ```-i / --ip``` | Host IP | host ip (e.g. 10.0.0.1) 입니다. <br /> 만약 클라우드(e.g, aws, gcp …) 등을 사용 할 경우, public IP가 아닌, private IP를 사용해야 합니다. |  |
| ```-kv / --k8sversion``` |  | 지원하는 쿠버네티스 버전을 보여줍니다. |  |
| ```-m / --master``` |  | master 노드를 생성하고자 하는 경우 ```-m``` 플래그를 사용하면 됩니다. | ```-i/--ip``` 플래그가 반드시 요구됩니다. |
| ```-p / --password``` | Master(Host) node password | ssh 로그인시 마스터 노드에 접속하기 위한 비밀번호입니다. <br /> 같은 서브넷 안에서 worker 노드 생성시 master 노드로부터 token을 갖고오기 위한 옵션입니다.  | ```-u/--username``` 플래그와 반드시 같이 사용해야합니다. |
| ```-r / --regularuser``` <br /> **(\*beta)** | HOME_PATH of regular user | 현재 sudo 권한으로 실행한 user 외에 다른 일반 유저에 대해서도 접근 권한을 부여하고자 할 때 사용합니다. <br /> ```-r /home/username``` 과 같이 사용하며, 이 때 HOME_PATH는 반드시 **해당 계정의 홈 디렉토리($HOME)** 이어야 합니다. | 선택 옵션이나, ```-m``` (마스터 노드 생성) 때에만 사용되는 옵션입니다. |
| ```-u / --username``` | Master(Host) node username | ssh 로그인시 마스터 노드에 접속하기 위한 username입니다. <br /> 같은 서브넷 안에서 worker 노드 생성시 master 노드로부터 token을 갖고오기 위한 옵션입니다.  | ```-p/--password``` 옵션과 반드시 같이 사용해야합니다. |
| ```-v / --version``` | k8s version | Kubernetes 버전을 설정하기 위해 사용됩니다. <br /> (e.g. -v 1.25.0)  <br />지원 버전은 ```1.24.15``` 부터 ```1.27.5``` 까지이며 지원 버전을 상세하게 보고자 한다면 ```-kv``` 또는 <br /> ```--k8sversion``` 옵션을 통해 확인이 가능합니다. | 해당 옵션을 사용하고자 하는 경우 파라미터는 ```x.y.z``` 형식으로 주어져야 합니다. <br /> 만약 해당 옵션을 사용하지 않을 경우 기본 버전은 ```1.24.15``` 이며 RC 또는 beta 버전의 경우 정식 릴리즈 버전이 아니므로 지원하지 않습니다. |
| ```-w / --worker``` |  | worker 노드를 생성하고자 하는 경우 -w 플래그를 사용하면 됩니다. | ```-i/--ip``` , ```-u/--username```, ```-p/-password``` 3개의 옵션이 반드시 요구됩니다. |

<br />
<br />

어떠한 옵션도 사용하지 않고 실행할 경우 쿠버네티스 클러스터 구성에 필요한 패키지 설치까지만 진행됩니다.

패키지 설치만 할 경우 사용자가 kubeadm init 명령을 실행하여 쿠버네티스 클러스터를 구성할 수 있습니다.

master 노드 생성 예)

```bash
sudo ./k8s-cluster-bootstrap.sh -m -c 192.168.0.0/16 -i 10.0.0.1 -ct containerd -v 1.25.0
```
<br />   

worker 노드 생성 예)

```bash
sudo ./k8s-cluster-bootstrap.sh -w -i 10.0.0.1 -u username -p pwd123!
```

<br />

## 기여 가이드라인
** 이 프로젝트에 기여를 하고자 한다면 
[기여 가이드라인](.github/CONTRIBUTING.md) 을 읽어보시기를 바랍니다.**
