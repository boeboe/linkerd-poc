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

.PHONY: info clean

deploy-linkerd: ## Deploy linkerd using helm charts
	./linkerd.sh deploy

undeploy-linkerd: ## Undeploy linkerd using helm charts
	./linkerd.sh undeploy

info: ## Print kind cluster information and kubectl info
	./info.sh

clean: ## Clean all temporary artifacts
	rm -rf ./output/*

######################
##### Scenarios ######
######################

.PHONY: deploy-http undeploy-http deploy-https undeploy-https

deploy-http: ## Deploy Nginx as plain HTTP with Nginx Ingress
	./http.sh deploy

undeploy-http: ## Undeploy Nginx as plain HTTP with Nginx Ingress
	./http.sh undeploy

deploy-https: ## Deploy Nginx as mutual TLS HTTPS with Nginx Ingress
	./https.sh deploy

undeploy-https: ## Undeploy Nginx as mutual TLS HTTPS with Nginx Ingress
	./https.sh undeploy

load-tests: ## Start k6 based load tests
	./load.sh
