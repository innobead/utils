#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

KUBECONFIG=${KUBECONFIG:~/.kube/config}

function install_tiller() {
  kubectl apply -f manifests

  helm init --service-account tiller
}

install_tiller
