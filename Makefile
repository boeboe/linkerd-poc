# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

#################
##### Setup #####
#################

.PHONY: up-kind up-linkerd up down monitoring info reset clean

reset: down clean up ## Reset the kind cluster and Linkerd installation
up: up-kind up-linkerd ## Spin up a kind cluster and install/upgrade Linkerd

up-kind: ## Spin up a kind cluster
	./up-kind.sh

up-linkerd: ## Install/upgrade Linkerd using Helm with NodePort for ingress gateway
	./up-linkerd.sh

down: ## Destroy the kind cluster
	./down.sh

monitoring: ## Install Prometheus and Grafana using Helm
	./monitoring.sh

info: ## Print kind cluster information and kubectl info
	./info.sh

clean: ## Clean all temporary artifacts
	rm -rf ./output/*

######################
##### Scenarios ######
######################

.PHONY: deploy-plain-http undeploy-plain-http deploy-mtls-https undeploy-mtls-https

deploy-plain-http: ## Deploy Nginx as plain HTTP with Nginx Ingress Gateway and Linkerd
	./plain-http.sh deploy

undeploy-plain-http: ## Undeploy Nginx as plain HTTP with Nginx Ingress Gateway and Linkerd
	./plain-http.sh undeploy

deploy-mtls-https: ## Deploy Nginx as Mutual TLS HTTPS with Nginx Ingress Gateway and Linkerd
	./mtls-https.sh deploy

undeploy-mtls-https: ## Undeploy Nginx as Mutual TLS HTTPS with Nginx Ingress Gateway and Linkerd
	./mtls-https.sh undeploy
