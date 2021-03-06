#!/usr/bin/env bash

set -o errexit

# Import libs
LIB_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
# shellcheck disable=SC1090
source "${LIB_DIR}"/_init.sh

# Constants
REG_VERSION=${REG_VERSION:-}
TERRAFORM_VERSION=${TERRAFORM_VERSION:-}
MKCERT_VERSION=${MKCERT_VERSION:-}
CFSSL_VERSION=${CFSSL_VERSION:-}
MC_VERSION=${MC_VERSION:-}

function install_terraform() {
  if [[ -z $TERRAFORM_VERSION ]]; then
    TERRAFORM_VERSION=$(git_release_version hashicorp/terraform)
    TERRAFORM_VERSION=${TERRAFORM_VERSION/v/$''}
  fi

  # shellcheck disable=SC2076
  if ! check_cmd terraform || [[ ! "$(terraform version)" =~ "$TERRAFORM_VERSION" ]]; then
    curl -sSfLO "https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    unzip terraform*.zip && rm terraform*.zip
    chmod +x terraform && sudo mv terraform /usr/local/bin
  fi

  if ! check_cmd ~/.terraform.d/plugins/terraform-provider-libvirt; then
    curl -sSfLO "https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v0.5.2/terraform-provider-libvirt-0.5.2.openSUSE_Leap_15.1.x86_64.tar.gz"
    tar -zxvf terraform-provider-libvirt*.tar.gz && rm terraform-provider-libvirt*.tar.gz
    mkdir -p ~/.terraform.d/plugins
    mv terraform-provider-libvirt ~/.terraform.d/plugins
  fi
}

function install_oci_tools() {
  pkgs=(
    podman
    buildah
    skopeo
    umoci
    helm-mirror
  )
  zypper_pkg_install "${pkgs[@]}"

  # enable rootless container
  sudo usermod --add-subuids 10000-75535 "$(whoami)"
  sudo usermod --add-subgids 10000-75535 "$(whoami)"
  podman system migrate
  podman unshare cat /proc/self/uid_map

  if [[ -z $REG_VERSION ]]; then
    REG_VERSION=$(git_release_version genuinetools/reg)
  fi

  # shellcheck disable=SC2076
  if ! check_cmd reg || [[ ! "$(reg version)" =~ "$REG_VERSION" ]]; then
    curl -sSfL -o reg "https://github.com/genuinetools/reg/releases/download/$REG_VERSION/reg-linux-amd64"
    sudo install reg "$KU_INSTALL_BIN"
  fi
}

function install_salt() {
  curl -sSfL -o bootstrap-salt.sh "https://bootstrap.saltstack.com"
  sudo bootstrap-salt.sh
}

function install_cert_tools() {
  sudo zypper in -y mozilla-nss-tools

  if [[ -z $MKCERT_VERSION ]]; then
    MKCERT_VERSION=$(git_release_version FiloSottile/mkcert)
  fi

  if ! check_cmd mkcert; then
    curl -sSfL -o mkcert "https://github.com/FiloSottile/mkcert/releases/download/$MKCERT_VERSION/mkcert-$MKCERT_VERSION-linux-amd64" &&
      sudo install mkcert "$KU_INSTALL_BIN"
  fi

  if [[ -z $CFSSL_VERSION ]]; then
    CFSSL_VERSION=$(git_release_version cloudflare/cfssl)
  fi

  if ! check_cmd cfssl || [[ ! "$(cfssl vesion)" =~ ${CFSSL_VERSION:1} ]]; then
    files=(cfssl-bundle cfssl-certinfo cfssl-newkey cfssl-scan cfssljson cfssl mkbundle multirootca)

    for f in "${files[@]}"; do
      curl -sSfL "https://github.com/cloudflare/cfssl/releases/download/$CFSSL_VERSION/${f}_${CFSSL_VERSION:1}_linux_amd64" -o "/usr/local/bin/$f"
    done
  fi
}

function install_ldap_tools() {
  zypper_cmd=in
  if check_cmd ldapsearch; then
    zypper_cmd=up
  fi

  # shellcheck disable=SC2086
  sudo zypper $zypper_cmd $KU_ZYPPER_INSTALL_OPTS openldap2-client
}

function install_cloud_tools() {
  pip install --upgrade awscli

  if [[ -f ~/.aws/credentials ]]; then
    cat <<EOF >~/.aws/credentials
[default]
aws_access_key_id =
aws_secret_access_key =
EOF
  fi

  #TODO azure does not support non-interactive install yet
  curl -L https://aka.ms/InstallAzureCli | bash

  curl https://sdk.cloud.google.com >install.sh
  # shellcheck disable=SC2086
  bash install.sh --disable-prompts --install-dir=$KU_INSTALL_DIR
  rm install.sh

  if ! grep "GCLOUD_PATH" /home/"$KU_USER"/.bashrc; then
    cat <<EOF >>/home/"$KU_USER"/.bashrc
export GCLOUD_PATH=$KU_INSTALL_DIR/google-cloud-sdk
export PATH=\$GCLOUD_PATH/bin:\$PATH
EOF
  fi
}

function install_circleci() {
  curl -fLSs https://circle.ci/cli | bash
}

function install_skaffold() {
  install_kubectl

  if [[ -z $SKAFFOLD_VERSION ]]; then
    SKAFFOLD_VERSION=$(git_release_version GoogleContainerTools/skaffold)
  fi

  if ! check_cmd skaffold || [[ ! "$(skaffold version)" =~ $SKAFFOLD_VERSION ]]; then
    curl -fsSL -o skaffold "https://github.com/GoogleContainerTools/skaffold/releases/download/$SKAFFOLD_VERSION/skaffold-linux-amd64"
    chmod +x skaffold
    sudo mv skaffold "$KU_INSTALL_BIN"
  fi
}

function install_mc() {
  # shellcheck disable=SC2076
  if ! check_cmd mc || [[ ! "$(mc --version)" =~ "$MC_VERSION" ]]; then
    curl -fsSLO "https://dl.min.io/client/mc/release/linux-amd64/mc"
    chmod +x mc
    sudo mv mc "$KU_INSTALL_BIN"
  fi
}
