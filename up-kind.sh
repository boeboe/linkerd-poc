#!/usr/bin/env bash
export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${BASE_DIR}/env.sh
# set -e

if ! kind get clusters | grep -q "${CLUSTER_NAME}"; then
    print_info "Creating kind cluster named ${CLUSTER_NAME}..."
    kind create cluster --name "${CLUSTER_NAME}"
else
    print_info "Kind cluster ${CLUSTER_NAME} already exists."
fi

echo "Waiting for kind cluster to be ready..."
until kubectl cluster-info --context "${KUBECONTEXT}" >/dev/null 2>&1; do
    print_info "Waiting for Kubernetes API to be available..."
    sleep 5
done

print_info "Setting kubeconfig context to ${KUBECONTEXT}..."
kubectl config use-context "${KUBECONTEXT}"