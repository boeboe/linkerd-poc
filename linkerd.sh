#!/usr/bin/env bash
export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${BASE_DIR}/env.sh
# set -e

CERTS_DIR="${BASE_DIR}/output/linkerd"
CA_KEY="${CERTS_DIR}/ca.key"
CA_CRT="${CERTS_DIR}/ca.crt"
ISSUER_KEY="${CERTS_DIR}/issuer.key"
ISSUER_CSR="${CERTS_DIR}/issuer.csr"
ISSUER_CRT="${CERTS_DIR}/issuer.crt"

# Function to generate Linkerd certificates
generate_linkerd_certs() {
  mkdir -p "${CERTS_DIR}"

  if [[ ! -f "${CA_KEY}" || ! -f "${CA_CRT}" ]]; then
    print_info "Generating CA key and certificate..."
    openssl ecparam -name prime256v1 -genkey -noout -out "${CA_KEY}"
    openssl req -x509 -new -key "${CA_KEY}" -sha256 -days 3650 \
      -out "${CA_CRT}" -subj "/CN=identity.linkerd.cluster.local"
  else
    print_info "CA key and certificate already exist. Skipping generation."
  fi

  if [[ ! -f "${ISSUER_KEY}" || ! -f "${ISSUER_CRT}" ]]; then
    print_info "Generating issuer key, CSR, and certificate..."
    openssl ecparam -name prime256v1 -genkey -noout -out "${ISSUER_KEY}"
    openssl req -new -key "${ISSUER_KEY}" -out "${ISSUER_CSR}" -subj "/CN=identity.linkerd.cluster.local"
    openssl x509 -req -in "${ISSUER_CSR}" -CA "${CA_CRT}" -CAkey "${CA_KEY}" \
      -set_serial 0 -days 3650 -sha256 \
      -out "${ISSUER_CRT}" \
      -extfile <(printf "basicConstraints=CA:TRUE,pathlen:0\nkeyUsage=critical,digitalSignature,keyCertSign,cRLSign\nsubjectAltName=DNS:identity.linkerd.cluster.local")
    rm -f "${ISSUER_CSR}"
  else
    print_info "Issuer key and certificate already exist. Skipping generation."
  fi

  print_info "Certificates are available in: ${CERTS_DIR}"
}

# Function to deploy Linkerd
deploy_linkerd() {
  print_info "Adding Linkerd Helm repository..."
  helm repo add linkerd https://helm.linkerd.io/stable || true
  helm repo update

  print_info "Generating Linkerd certificates..."
  generate_linkerd_certs

  print_info "Installing or upgrading Linkerd components..."
  # Install Linkerd CRDs
  helm upgrade --install linkerd-crds linkerd/linkerd-crds \
    --namespace "${LINKERD_NS}" \
    --create-namespace \
    --version "${LINKERD_CRDS_VERSION}" \
    --wait

  # Install Linkerd Control Plane
  helm upgrade --install linkerd-control-plane linkerd/linkerd-control-plane \
    --namespace "${LINKERD_NS}" \
    --version "${LINKERD_CONTROLPLANE_VERSION}" \
    --set-file identityTrustAnchorsPEM="${CA_CRT}" \
    --set-file identity.issuer.tls.crtPEM="${ISSUER_CRT}" \
    --set-file identity.issuer.tls.keyPEM="${ISSUER_KEY}" \
    --wait

  print_info "Waiting for Linkerd pods to be ready..."
  until kubectl get pods -n "${LINKERD_NS}" >/dev/null 2>&1; do
      print_info "Waiting for Linkerd resources to be created..."
      sleep 5
  done
  kubectl wait --for=condition=Ready pods --all -n "${LINKERD_NS}" --timeout=300s
}

# Function to undeploy Linkerd
undeploy_linkerd() {
  print_info "Removing Linkerd components..."

  # Delete Linkerd Control Plane
  helm uninstall linkerd-control-plane --namespace "${LINKERD_NS}"

  # Delete Linkerd CRDs
  helm uninstall linkerd-crds --namespace "${LINKERD_NS}"

  print_info "Cleaning up Linkerd namespace..."
  kubectl delete namespace linkerd
}

# Check input parameter to determine deploy or undeploy
if [[ "$1" == "deploy" ]]; then
  deploy_linkerd
elif [[ "$1" == "undeploy" ]]; then
  undeploy_linkerd
else
  print_error "Invalid argument. Use 'deploy' or 'undeploy'."
  exit 1
fi