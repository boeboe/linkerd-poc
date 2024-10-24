#!/usr/bin/env bash
export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${BASE_DIR}/env.sh
# set -e

if ! command_exists k6; then
    print_error "Error: 'k6' is not installed. Please install k6 before proceeding."
    exit 1
fi

print_info "\nFetching Linkerd ingress gateway LoadBalancer IP and exposed ports..."
INGRESS_EXTERNAL_IP=$(kubectl get svc "${LINKERD_INGRESS_SVC}" -n "${LINKERD_INGRESS_NS}" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
INGRESS_HTTP_PORT=$(kubectl get svc "${LINKERD_INGRESS_SVC}" -n "${LINKERD_INGRESS_NS}" -o jsonpath='{.spec.ports[?(@.name=="http")].port}')
INGRESS_HTTPS_PORT=$(kubectl get svc "${LINKERD_INGRESS_SVC}" -n "${LINKERD_INGRESS_NS}" -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
print_info "Linkerd ingress gateway is available at http://${INGRESS_EXTERNAL_IP}:${INGRESS_HTTP_PORT} and https://${INGRESS_EXTERNAL_IP}:${INGRESS_HTTPS_PORT}"

print_info "\nGoing to login k6 to Grafana Cloud, please specify a valid API token (leave empty for local test):"
read -p "TOKEN: " GRAFANA_CLOUD_TOKEN
if [[ -z "$GRAFANA_CLOUD_TOKEN" ]]; then
  print_warning "Warning: no Grafa Cloud token provided, results will not be stored in the cloud!"

  print_info "\nStart load testing scenario for http scenario:"
  print_command "k6 run -e INGRESS_HTTP_PORT=${INGRESS_HTTP_PORT} -e INGRESS_HTTPS_PORT=${INGRESS_HTTPS_PORT} -e DNS_SUFFIX=${DNS_SUFFIX} -e PROJECT_ID=\"3718221\" -e TEST_SCENARIO=\"http\" load.js"
  k6 run \
    -e INGRESS_HTTP_PORT=${INGRESS_HTTP_PORT} \
    -e INGRESS_HTTPS_PORT=${INGRESS_HTTPS_PORT} \
    -e DNS_SUFFIX=${DNS_SUFFIX} \
    -e PROJECT_ID="3718221" \
    -e TEST_SCENARIO="http" \
    load.js

  print_info "\nStart load testing scenario for https scenario:"
  print_command "k6 run --insecure-skip-tls-verify -e INGRESS_HTTP_PORT=${INGRESS_HTTP_PORT} -e INGRESS_HTTPS_PORT=${INGRESS_HTTPS_PORT} -e DNS_SUFFIX=${DNS_SUFFIX} -e PROJECT_ID=\"3718221\" -e TEST_SCENARIO=\"https\" load.js"
  k6 run --insecure-skip-tls-verify \
    -e INGRESS_HTTP_PORT=${INGRESS_HTTP_PORT} \
    -e INGRESS_HTTPS_PORT=${INGRESS_HTTPS_PORT} \
    -e DNS_SUFFIX=${DNS_SUFFIX} \
    -e PROJECT_ID="3718221" \
    -e TEST_SCENARIO="https" \
    load.js
else
  k6 cloud login --token "$GRAFANA_CLOUD_TOKEN"

  print_info "\nStart load testing scenario for http scenario:"
  print_command "k6 cloud run --local-execution -e INGRESS_HTTP_PORT=${INGRESS_HTTP_PORT} -e INGRESS_HTTPS_PORT=${INGRESS_HTTPS_PORT} -e DNS_SUFFIX=${DNS_SUFFIX} -e PROJECT_ID=\"3718221\" -e TEST_SCENARIO=\"http\" load.js"
  k6 cloud run --local-execution \
    -e INGRESS_HTTP_PORT=${INGRESS_HTTP_PORT} \
    -e INGRESS_HTTPS_PORT=${INGRESS_HTTPS_PORT} \
    -e DNS_SUFFIX=${DNS_SUFFIX} \
    -e PROJECT_ID="3718221" \
    -e TEST_SCENARIO="http" \
    load.js

  print_info "\nStart load testing scenario for https scenario:"
  print_command "k6 cloud run --insecure-skip-tls-verify --local-execution -e INGRESS_HTTP_PORT=${INGRESS_HTTP_PORT} -e INGRESS_HTTPS_PORT=${INGRESS_HTTPS_PORT} -e DNS_SUFFIX=${DNS_SUFFIX} -e PROJECT_ID=\"3718221\" -e TEST_SCENARIO=\"https\" load.js"
  k6 cloud run --insecure-skip-tls-verify --local-execution \
    -e INGRESS_HTTP_PORT=${INGRESS_HTTP_PORT} \
    -e INGRESS_HTTPS_PORT=${INGRESS_HTTPS_PORT} \
    -e DNS_SUFFIX=${DNS_SUFFIX} \
    -e PROJECT_ID="3718221" \
    -e TEST_SCENARIO="https" \
    load.js
fi


