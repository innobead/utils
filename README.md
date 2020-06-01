# k8s-utils

A shell CLI to install useful packages, tools, and systems for Containers/Kuberentes development purpose. 

Note: we are planning to run by OCI `container runtime` directly in near future to avoid `container runtime manager` dependency.

## Prerequisites

- openSUSE LEAP 15.x
- openSUSE Tumbleweed
- Docker 19.03

## Installing tools
```
➜  k8s-utils git:(master) ./bin/install.sh                                                       
Configurable Variables:
 KU_FORCE_INSTALL=false
 KU_INSTALL_BIN=/usr/local/bin
 KU_INSTALL_DIR=/usr/local/lib
 KU_SKIP_SETUP=true
 KU_TMP_DIR=/tmp
 KU_USER=davidko
 KU_ZYPPER_INSTALL_OPTS='-y -l'

Command Usage:
  ./bin/install.sh init

  ./bin/install.sh <package name>
   - bazel
   - bcrypt
   - cert_tools
   - circleci
   - cloud_tools
   - cni_plugins
   - containerd
   - controllertools
   - crio
   - direnv
   - docker
   - footloose
   - gimme
   - go
   - go_dev_tools
   - gofish
   - gradle
   - helm
   - hub
   - ignite
   - jwt
   - kind
   - krew
   - kubebuilder
   - kubectl
   - kustomize
   - ldap_tools
   - libvirt
   - lxc
   - mc
   - minikube
   - oci_tools
   - podman
   - protobuf
   - python
   - rust
   - salt
   - sdkman
   - skaffold
   - snap
   - suse_caasp_env
   - suse_sles_images
   - terraform
   - vagrant
   - velero
   - virtualbox
   - all
```

## Installing tools (via Container with the same user namespace and system library mounted folders)
```
➜  k8s-utils git:(master) ./k8sutil.sh
```

## Deploying applications/services
```
➜  k8s-utils git:(master) ✗ ./deploy/kind/install.sh 
➜  k8s-utils git:(master) ✗ ./deploy/kind/uninstall.sh 
```