#!/usr/bin/env bash
export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${BASE_DIR}/env.sh
# set -e

CERTS_DIR="${BASE_DIR}/output/certs"
CA_KEY="${CERTS_DIR}/ca.key"
CA_CRT="${CERTS_DIR}/ca.crt"
ISSUER_KEY="${CERTS_DIR}/issuer.key"
ISSUER_CSR="${CERTS_DIR}/issuer.csr"
ISSUER_CRT="${CERTS_DIR}/issuer.crt"

# Function to generate Linkerd certificates
generate_linkerd_certs() {
  # Create the output directory if it doesn't exist
  mkdir -p "${CERTS_DIR}"

  # Generate CA key and certificate if they do not exist
  if [[ ! -f "${CA_KEY}" || ! -f "${CA_CRT}" ]]; then
    print_info "Generating CA key and certificate..."
    openssl ecparam -name prime256v1 -genkey -noout -out "${CA_KEY}"
    openssl req -x509 -new -key "${CA_KEY}" -sha256 -days 3650 \
      -out "${CA_CRT}" -subj "/CN=identity.linkerd.cluster.local"
  else
    print_info "CA key and certificate already exist. Skipping generation."
  fi

  # Generate issuer key, CSR, and certificate if they do not exist
  if [[ ! -f "${ISSUER_KEY}" || ! -f "${ISSUER_CRT}" ]]; then
    print_info "Generating issuer key, CSR, and certificate..."

    # Generate a private key for the issuer using ECDSA
    openssl ecparam -name prime256v1 -genkey -noout -out "${ISSUER_KEY}"

    # Create a certificate signing request (CSR) for the issuer
    openssl req -new -key "${ISSUER_KEY}" -out "${ISSUER_CSR}" -subj "/CN=identity.linkerd.cluster.local"

    # Sign the issuer CSR with the root CA to create the issuer certificate as an intermediate CA
    openssl x509 -req -in "${ISSUER_CSR}" -CA "${CA_CRT}" -CAkey "${CA_KEY}" \
      -set_serial 0 -days 3650 -sha256 \
      -out "${ISSUER_CRT}" \
      -extfile <(printf "basicConstraints=CA:TRUE,pathlen:0\nkeyUsage=critical,digitalSignature,keyCertSign,cRLSign\nsubjectAltName=DNS:identity.linkerd.cluster.local")
    
    # Clean up the CSR as it's no longer needed
    rm -f "${ISSUER_CSR}"
  else
    print_info "Issuer key and certificate already exist. Skipping generation."
  fi

  print_info "Certificates are available in: ${CERTS_DIR}"
}

print_info "Adding Linkerd Helm repository..."
helm repo add linkerd https://helm.linkerd.io/stable || true
print_info "Adding Nginx Ingress Helm repository..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
helm repo update

print_info "Generating Linkerd certificates..."
generate_linkerd_certs

print_info "Installing or upgrading Linkerd components..."
# Install Linkerd CRDs
helm upgrade --install linkerd-crds linkerd/linkerd-crds \
  --namespace linkerd \
  --create-namespace \
  --kube-context "${KUBECONTEXT}" \
  --version "${LINKERD_CRDS_VERSION}" \
  --wait

# Install Linkerd Control Plane
helm upgrade --install linkerd-control-plane linkerd/linkerd-control-plane \
  --namespace linkerd \
  --kube-context "${KUBECONTEXT}" \
  --version "${LINKERD_CONTROLPLANE_VERSION}" \
  --set-file identityTrustAnchorsPEM="${CA_CRT}" \
  --set-file identity.issuer.tls.crtPEM="${ISSUER_CRT}" \
  --set-file identity.issuer.tls.keyPEM="${ISSUER_KEY}" \
  --wait

print_info "Installing or upgrading Nginx Ingress..."

# Install Nginx Ingress Controller with NodePort configuration
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=${INGRESS_HTTP_PORT} \
  --set controller.service.nodePorts.https=${INGRESS_HTTPS_PORT} \
  --wait

print_info "Waiting for Linkerd pods to be ready..."
until kubectl get pods -n linkerd --context "${KUBECONTEXT}" >/dev/null 2>&1; do
    print_info "Waiting for Linkerd resources to be created..."
    sleep 5
done
kubectl wait --for=condition=Ready pods --all -n linkerd --timeout=300s --context "${KUBECONTEXT}"

print_info "Waiting for ingress-nginx pods to be ready..."
until kubectl get pods -n ingress-nginx --context "${KUBECONTEXT}" >/dev/null 2>&1; do
    print_info "Waiting for ingress-nginx resources to be created..."
    sleep 5
done
kubectl wait --for=condition=Ready pods --all -n ingress-nginx --timeout=300s --context "${KUBECONTEXT}"
