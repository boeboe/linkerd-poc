#!/usr/bin/env bash

# Setup Environment Variables
export ENVIRONMENT="gwc-plsdev"
# export ENVIRONMENT="gwc-plstst"


export LINKERD_NS="linkerd"
export LINKERD_INGRESS_NS="ingress-nginx-meshed"
export LINKERD_CRDS_VERSION="1.8.0"
export LINKERD_CONTROLPLANE_VERSION="1.16.11"
export LINKERD_INGRESS_SVC="ingress-nginx-meshed-controller"
export LINKERD_INGRESS_CLASS="nginx-meshed"

# Colors
end="\033[0m"
black="\033[0;30m"
blackb="\033[1;30m"
white="\033[0;37m"
whiteb="\033[1;37m"
red="\033[0;31m"
redb="\033[1;31m"
green="\033[0;32m"
greenb="\033[1;32m"
yellow="\033[0;33m"
yellowb="\033[1;33m"
blue="\033[0;34m"
blueb="\033[1;34m"
purple="\033[0;35m"
purpleb="\033[1;35m"
lightblue="\033[0;36m"
lightblueb="\033[1;36m"

# Print info messages
function print_info {
  echo -e "${greenb}${1}${end}"
}

# Print warning messages
function print_warning {
  echo -e "${yellowb}${1}${end}"
}

# Print error messages
function print_error {
  echo -e "${redb}${1}${end}"
}

# Print command messages
function print_command {
  echo -e "${lightblueb}${1}${end}"
}

export -f print_info print_warning print_error print_command

function command_exists() {
    command -v "$1" >/dev/null 2>&1
}

if ! command_exists kubectl; then
    print_error "Error: 'kubectl' is not installed. Please install kubectl before proceeding."
    exit 1
fi

if ! command_exists helm; then
    print_error "Error: 'helm' is not installed. Please install helm before proceeding."
    exit 1
fi

case "${ENVIRONMENT}" in
  gwc-plsdev)
    print_info "Setting env variables for 'gwc-plsdev'"
    export AZ_SUBSCRIPTION="e318542a-815a-46d8-93ab-15fabdd926ed"
    export AZ_RESOURCEGROUP="rg-apps-1-gwc-plsdev"
    export AZ_AKS_NAME="aks-apps-1-gwc-plsdev"
    export KUBECONTEXT="aks-apps-1-gwc-plsdev"
    export DNS_SUFFIX="development.staging.platform.liantis.net"
    ;;

  gwc-plstst)
    print_info "Setting env variables for 'gwc-plstst'"
    export AZ_SUBSCRIPTION="7ec20f55-30d9-4fe6-92ec-ee01918c6a38"
    export AZ_RESOURCEGROUP="rg-apps-1-gwc-plstst"
    export AZ_AKS_NAME="aks-apps-1-gwc-plstst"
    export KUBECONTEXT="aks-apps-1-gwc-plstst"
    export DNS_SUFFIX="test.staging.platform.liantis.net"
    ;;

  *)
    print_error "ENVIRONMENT must be one of 'gwc-plsdev' or 'gwc-plstst'"
    exit 1
    ;;
esac

# Check if the context exists
if ! kubectl config get-contexts "${KUBECONTEXT}" &>/dev/null; then
  print_error "Error: Kubernetes context '${KUBECONTEXT}' does not exist."
  exit 1
fi

# Get the current context
CURRENT_CONTEXT=$(kubectl config current-context)

# If the current context is not the target context, switch to it
if [ "${CURRENT_CONTEXT}" != "${KUBECONTEXT}" ]; then
  print_info "Switching to Kubernetes context '${KUBECONTEXT}'..."
  kubectl config use-context "${KUBECONTEXT}"
else
  print_info "Already using Kubernetes context '${KUBECONTEXT}'."
fi 
