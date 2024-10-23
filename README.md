# Linkerd POC

## Overview

This project provides a Proof of Concept (PoC) for deploying a Kubernetes cluster using kind and installing Linkerd using helm. The deployment can be controlled using the provided Makefile targets and bash scripts, which offer a convenient way to manage the cluster and Linkerd components.

## Prerequisites

Ensure you have the following tools installed before proceeding:

	•	kind
	•	kubectl
	•	helm

## Usage

The following targets are defined in the [Makefile](./Makefile):

```console
$ make

help                           This help
reset                          Reset the kind cluster and Linkerd installation
up                             Spin up a kind cluster and install/upgrade Linkerd
up-kind                        Spin up a kind cluster
up-linkerd                     Install/upgrade Linkerd using Helm with NodePort for ingress gateway
down                           Destroy the kind cluster
monitoring                     Install Prometheus and Grafana using Helm
info                           Print kind cluster information and kubectl info
clean                          Clean all temporary artifacts
deploy-plain-http              Deploy Nginx as plain HTTP with Nginx Ingress Gateway and Linkerd
undeploy-plain-http            Undeploy Nginx as plain HTTP with Nginx Ingress Gateway and Linkerd
deploy-mtls-https              Deploy Nginx as Mutual TLS HTTPS with Nginx Ingress Gateway and Linkerd
undeploy-mtls-https            Undeploy Nginx as Mutual TLS HTTPS with Nginx Ingress Gateway and Linkerd
```

## Environment Variables

The environment variables used in this project are defined in [env.sh](./env.sh). These variables control the cluster name, the Kubernetes context, and the Istio version. Below are the variables that can be configured:

1. **CLUSTER_NAME**

	-	Description: The name of the Kubernetes cluster created by kind.
	-	Default Value: istio-cluster
	-	Usage: Set export CLUSTER_NAME="my-cluster" to use a custom cluster name.

2. **KUBECONTEXT**

	-	Description: The Kubernetes context to use, derived from the cluster name.
	-	Default Value: kind-$(CLUSTER_NAME)
	-	Usage: Set export KUBECONTEXT="my-context" if you want a specific Kubernetes context.

3. **ISTIO_VERSION**

	-	Description: The version of Istio to install using Helm.
	-	Default Value: 1.18.0
	-	Usage: Set export ISTIO_VERSION="1.17.0" to install a different version of Istio.
