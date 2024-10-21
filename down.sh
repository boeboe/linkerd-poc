#!/usr/bin/env bash
export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${BASE_DIR}/env.sh
# set -e

print_info "Destroying the kind cluster named ${CLUSTER_NAME}..."
kind delete cluster --name "${CLUSTER_NAME}"
