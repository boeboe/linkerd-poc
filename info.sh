#!/usr/bin/env bash
export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${BASE_DIR}/env.sh
# set -e

print_info "Kubectl context information:"
kubectl cluster-info

print_info "Kubernetes pods and services:"
kubectl get po,svc --all-namespaces -o wide

print_info "\nFetching Linkerd ingress gateway LoadBalancer IP and exposed ports..."
INGRESS_EXTERNAL_IP=$(kubectl get svc "${LINKERD_INGRESS_SVC}" -n "${LINKERD_INGRESS_NS}" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
INGRESS_HTTP_PORT=$(kubectl get svc "${LINKERD_INGRESS_SVC}" -n "${LINKERD_INGRESS_NS}" -o jsonpath='{.spec.ports[?(@.name=="http")].port}')
INGRESS_HTTPS_PORT=$(kubectl get svc "${LINKERD_INGRESS_SVC}" -n "${LINKERD_INGRESS_NS}" -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
print_info "Linkerd ingress gateway is available at http://${INGRESS_EXTERNAL_IP}:${INGRESS_HTTP_PORT} and https://${INGRESS_EXTERNAL_IP}:${INGRESS_HTTPS_PORT}"

print_info "\nTest traffic commands:"
print_command "curl http://perf-http-linkerd.${DNS_SUFFIX} --resolve perf-http-linkerd.${DNS_SUFFIX}:${INGRESS_HTTP_PORT}:${INGRESS_EXTERNAL_IP} -H 'TestScenario: perf-http-linkerd'"
print_command "curl https://perf-https-linkerd.${DNS_SUFFIX} --cacert output/https/wildcard-cert.pem  --resolve perf-https-linkerd.${DNS_SUFFIX}:${INGRESS_HTTPS_PORT}:${INGRESS_EXTERNAL_IP} -H 'TestScenario: perf-https-linkerd'"
