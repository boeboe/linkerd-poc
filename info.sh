#!/usr/bin/env bash
export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${BASE_DIR}/env.sh
# set -e

echo "Checking that the kubeconfig context is set to ${KUBECONTEXT}..."
CURRENT_CONTEXT=$(kubectl config current-context)
if [ "$CURRENT_CONTEXT" != "${KUBECONTEXT}" ]; then
    print_info "Current kubeconfig context (${CURRENT_CONTEXT}) does not match the expected context (${KUBECONTEXT}). Please switch to the correct context."
    exit 1
fi

print_info "Kind cluster information:"
kind get clusters

print_info "Kubectl context information:"
kubectl cluster-info --context "${KUBECONTEXT}"

print_info "Kubernetes pods and services:"
kubectl get po,svc --all-namespaces -o wide --context "${KUBECONTEXT}"

print_info "\nFetching ingress-nginx NodePort information..."
NGINX_INGRESS_PORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
NGINX_INGRESS_HTTPS_PORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
print_info "ingress-nginx is available at http://${NODE_IP}:${NGINX_INGRESS_PORT} and https://${NODE_IP}:${NGINX_INGRESS_HTTPS_PORT}"

print_info "\nFetching Grafana admin password..."
GRAFANA_ADMIN_PASSWORD=$(kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" --context "${KUBECONTEXT}" | base64 --decode)
print_info "Grafana admin password: ${GRAFANA_ADMIN_PASSWORD}"
