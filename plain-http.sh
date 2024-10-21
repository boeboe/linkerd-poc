#!/usr/bin/env bash
export BASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source ${BASE_DIR}/env.sh

MANIFEST_DIR="${BASE_DIR}/plain-http"

# Function to create necessary resources without TLS
function deploy_nginx_with_ingress {
  print_info "Creating namespace..."
  kubectl apply -f "${MANIFEST_DIR}/00-namespace.yaml" --context "${KUBECONTEXT}"

  print_info "Deploying Nginx service..."
  kubectl apply -f "${MANIFEST_DIR}/01-deployment.yaml" --context "${KUBECONTEXT}"
  kubectl apply -f "${MANIFEST_DIR}/02-service.yaml" --context "${KUBECONTEXT}"

  print_info "Deploying NGINX Ingress..."
  kubectl apply -f "${MANIFEST_DIR}/03-ingress.yaml" --context "${KUBECONTEXT}"

  print_info "Nginx has been deployed and exposed through the NGINX Ingress with HTTP."
}

# Function to undeploy Nginx with NGINX Ingress
function undeploy_nginx_with_ingress {
  print_info "Deleting NGINX Ingress..."
  kubectl delete -f "${MANIFEST_DIR}/03-ingress.yaml" --ignore-not-found --context "${KUBECONTEXT}"

  print_info "Deleting Nginx service..."
  kubectl delete -f "${MANIFEST_DIR}/02-service.yaml" --ignore-not-found --context "${KUBECONTEXT}"

  print_info "Deleting Nginx deployment..."
  kubectl delete -f "${MANIFEST_DIR}/01-deployment.yaml" --ignore-not-found --context "${KUBECONTEXT}"

  print_info "Deleting namespace..."
  kubectl delete -f "${MANIFEST_DIR}/00-namespace.yaml" --ignore-not-found --context "${KUBECONTEXT}"

  print_info "Nginx and Ingress resources have been undeployed."
}

# Check input parameter to determine deploy or undeploy
if [[ "$1" == "deploy" ]]; then
  deploy_nginx_with_ingress
elif [[ "$1" == "undeploy" ]]; then
  undeploy_nginx_with_ingress
else
  print_error "Invalid argument. Use 'deploy' or 'undeploy'."
  exit 1
fi