#!/usr/bin/env bash

set -o errexit

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_common.sh

# Constants
KUBE_VERSION=${KUBE_VERSION:-$(k8s_version)}
KIND_VERSION=${KIND_VERSION:-}
HELM_VERSION=${HELM_VERSION:-}
MKCERT_VERSION=${MKCERT_VERSION:-}
MINIKUBE_VERSION=${MINIKUBE_VERSION:-}
VELERO_VERSION=${VELERO_VERSION:-}
FOOTLOOSE_VERSION=${FOOTLOOSE_VERSION:-}

function install_kind() {
  if [[ -z $KIND_VERSION ]]; then
    KIND_VERSION=$(git_release_version kubernetes-sigs/kind)
  fi

  if ! check_cmd kind || [[ ! "$(kind version)" != "$KIND_VERSION" ]]; then
    pushd /tmp
    curl -sSfL -o kind "https://github.com/kubernetes-sigs/kind/releases/download/$KIND_VERSION/kind-linux-amd64" &&
      sudo install kind /usr/local/bin/
    popd
  fi
}

function install_minikube() {
  if ! grep -E --color 'vmx|svm' /proc/cpuinfo; then
    echo "No virtualization is supported."
    exit 1
  fi

  if [[ -z $MINIKUBE_VERSION ]]; then
    MINIKUBE_VERSION=$(git_release_version kubernetes/minikube)
  fi

  # shellcheck disable=SC2076
  if ! check_cmd minikube || [[ ! "$(minikube version)" =~ "$MINIKUBE_VERSION" ]]; then
    curl -sSfL -o minikube "https://github.com/kubernetes/minikube/releases/download/$MINIKUBE_VERSION/minikube-linux-amd64" &&
      sudo install minikube /usr/local/bin/
  fi

  cat <<EOF
If using kvm2 as vm-driver, please make sure default network is NAT to avoid unability to access internet to download necessary container images.

➜  ~ virsh net-dumpxml default
<network>
  <name>default</name>
  <uuid>13035582-7a70-4be0-804f-c00098f39e02</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:20:b9:fc'/>
  <domain name='default'/>
  <ip address='192.168.100.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.100.128' end='192.168.100.254'/>
    </dhcp>
  </ip>
</network>
EOF
}

function install_helm() {
  if [[ -z $HELM_VERSION ]]; then
    HELM_VERSION=$(git_release_version helm/helm)
  fi

  # shellcheck disable=SC2076
  if ! check_cmd helm || [[ ! "$(helm version --client)" =~ "$HELM_VERSION" ]]; then
    pushd /tmp
    curl -sSfLO "https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz" &&
      tar -zxvf helm-*.tar.gz --strip-components 1 &&
      rm helm-*.tar.gz
    chmod +x helm &&
      sudo mv helm /usr/local/bin/

    helm repo add stable https://kubernetes-charts.storage.googleapis.com
    popd
  fi
}

function install_mkcert() {
  if [[ -z $MKCERT_VERSION ]]; then
    MKCERT_VERSION=$(git_release_version FiloSottile/mkcert)
  fi

  if ! check_cmd mkcert; then
    pushd /tmp
    curl -sSfL -o mkcert "https://github.com/FiloSottile/mkcert/releases/download/$MKCERT_VERSION/mkcert-$MKCERT_VERSION-linux-amd64" &&
      sudo install mkcert /usr/local/bin/
    popd
  fi
}

function install_kubectl() {
  # shellcheck disable=SC2076
  if ! check_cmd kubectl || [[ ! "$(kubectl version --client)" =~ "$KUBE_VERSION" ]]; then
    pushd /tmp
    # shellcheck disable=SC2086
    curl -sSfLO "https://storage.googleapis.com/kubernetes-release/release/$KUBE_VERSION/bin/linux/amd64/kubectl" &&
      sudo install kubectl /usr/local/bin/
    popd
  fi
}

function install_velero() {
  if [[ -z $VELERO_VERSION ]]; then
    VELERO_VERSION=$(git_release_version vmware-tanzu/velero)
  fi

  if ! command -v velero || [[ "$(velero version --client-only)" != "$VELERO_VERSION" ]]; then
    f="velero-$VELERO_VERSION-linux-amd64.tar.gz"
    curl -sSfL -O "https://github.com/vmware-tanzu/velero/releases/download/$VELERO_VERSION/$f"

    mkdir velero &&
      tar zxvf "$f" --strip-components=1 -C velero &&
      rm "$f"

    chmod +x velero/velero && sudo mv velero/velero /usr/local/bin/
  fi
}

function install_footloose() {
    if [[ -z $FOOTLOOSE_VERSION ]]; then
      FOOTLOOSE_VERSION=$(git_release_version weaveworks/footloose)
    fi

    if ! command -v footloose || [[ ! "$(footloose version | awk '{print $2}')" =~ $FOOTLOOSE_VERSION ]]; then
      curl -sSfL -o footloose "https://github.com/weaveworks/footloose/releases/download/$FOOTLOOSE_VERSION/footloose-$FOOTLOOSE_VERSION-linux-x86_64"
      chmod +x footloose && sudo mv footloose /usr/local/bin
    fi
}