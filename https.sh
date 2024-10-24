#!/usr/bin/env bash
export BASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source ${BASE_DIR}/env.sh

MANIFEST_DIR="${BASE_DIR}/https"
CERT_DIR="${BASE_DIR}/output/https"

# Function to generate wildcard certificate and create Kubernetes secret
function create_tls_secret {
  # Check if the certificate files already exist
  if [[ -f "${CERT_DIR}/wildcard-key.pem" && -f "${CERT_DIR}/wildcard-cert.pem" && -f "${CERT_DIR}/wildcard.csr" ]]; then
    print_info "Certificate and key already exist, skipping generation."
  else
    print_info "Generating wildcard certificate and private key..."
    mkdir -p "${CERT_DIR}"

    # Generate a private key
    openssl genrsa -out "${CERT_DIR}/wildcard-key.pem" 2048

    # Create a certificate signing request (CSR)
    openssl req -new -key "${CERT_DIR}/wildcard-key.pem" -out "${CERT_DIR}/wildcard.csr" -subj "/CN=*.${DNS_SUFFIX}/O=Liantis"

    # Self-sign the certificate
    openssl x509 -req -in "${CERT_DIR}/wildcard.csr" -signkey "${CERT_DIR}/wildcard-key.pem" -out "${CERT_DIR}/wildcard-cert.pem" -days 365
  fi

  # Create the Kubernetes secret for the certificate and key if it doesn't already exist
  print_info "Checking if Kubernetes secret for the wildcard certificate already exists..."

  if ! kubectl get secret perf-https-linkerd-certs -n "${LINKERD_INGRESS_NS}" &>/dev/null; then
    print_info "Creating Kubernetes secret for the wildcard certificate..."
    kubectl create -n "${LINKERD_INGRESS_NS}" secret tls perf-https-linkerd-certs \
      --cert="${CERT_DIR}/wildcard-cert.pem" \
      --key="${CERT_DIR}/wildcard-key.pem" --dry-run=client -o yaml | kubectl apply -f -
    print_info "TLS secret has been created."
  else
    print_info "Kubernetes secret 'perf-https-linkerd-certs' already exists. Skipping creation."
  fi
}


# Function to remove the Kubernetes secret for the wildcard certificate
function remove_tls_secret {
  print_info "Deleting Kubernetes secret for the wildcard certificate..."
  kubectl delete secret perf-https-linkerd-certs -n "${LINKERD_INGRESS_NS}" --ignore-not-found
  print_info "TLS secret has been deleted."
}

# Function to deploy Nginx with NGINX Ingress and Linkerd
function deploy_nginx_with_ingress {
  create_tls_secret

  print_info "Creating namespace..."
  kubectl apply -f "${MANIFEST_DIR}/00-namespace.yaml"

  print_info "Deploying Nginx service..."
  kubectl apply -f "${MANIFEST_DIR}/01-deployment.yaml"
  kubectl apply -f "${MANIFEST_DIR}/02-service.yaml"

  print_info "Deploying Nginx Ingress..."
  envsubst < ${MANIFEST_DIR}/03-ingress.yaml | kubectl apply -f -

  print_info "Deploying Linkerd ServerAuthorization..."
  kubectl apply -f "${MANIFEST_DIR}/04-serverauthorization.yaml"

  print_info "Nginx has been deployed and exposed through the Nginx Ingress (Mutual TLS HTTPS)."
}

# Function to undeploy Nginx with NGINX Ingress
function undeploy_nginx_with_ingress {
  print_info "Deleting Linkerd ServerAuthorization..."
  kubectl delete -f "${MANIFEST_DIR}/04-serverauthorization.yaml" --ignore-not-found

  print_info "Deleting Nginx Ingress..."
  kubectl delete -f "${MANIFEST_DIR}/03-ingress.yaml" --ignore-not-found

  print_info "Deleting Nginx service..."
  kubectl delete -f "${MANIFEST_DIR}/02-service.yaml" --ignore-not-found

  print_info "Deleting Nginx deployment..."
  kubectl delete -f "${MANIFEST_DIR}/01-deployment.yaml" --ignore-not-found

  print_info "Deleting namespace..."
  kubectl delete -f "${MANIFEST_DIR}/00-namespace.yaml" --ignore-not-found

  # Remove the TLS secret
  remove_tls_secret

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