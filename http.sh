#!/usr/bin/env bash
export BASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source ${BASE_DIR}/env.sh

MANIFEST_DIR="${BASE_DIR}/http"

# Function to create necessary resources without TLS
function deploy_nginx_with_ingress {
  print_info "Creating namespace..."
  kubectl apply -f "${MANIFEST_DIR}/00-namespace.yaml"

  print_info "Deploying Nginx service..."
  kubectl apply -f "${MANIFEST_DIR}/01-deployment.yaml"
  kubectl apply -f "${MANIFEST_DIR}/02-service.yaml"

  print_info "Deploying Nginx Ingress..."
  envsubst < ${MANIFEST_DIR}/03-ingress.yaml | kubectl apply -f -

  print_info "Nginx has been deployed and exposed through the Nginx ingress gateway (HTTP only)."
}

# Function to undeploy Nginx with NGINX Ingress
function undeploy_nginx_with_ingress {
  print_info "Deleting Nginx Ingress..."
  kubectl delete -f "${MANIFEST_DIR}/03-ingress.yaml" --ignore-not-found

  print_info "Deleting Nginx service..."
  kubectl delete -f "${MANIFEST_DIR}/02-service.yaml" --ignore-not-found

  print_info "Deleting Nginx deployment..."
  kubectl delete -f "${MANIFEST_DIR}/01-deployment.yaml" --ignore-not-found

  print_info "Deleting namespace..."
  kubectl delete -f "${MANIFEST_DIR}/00-namespace.yaml" --ignore-not-found

  print_info "Nginx and Linkerd resources have been undeployed."
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