CMD:=kubectl apply
ARGS:=$(shell cat .args)

.PHONY: cert-manager
# Install cert-manager
cert-manager:
	$(CMD) -f ./cert-manager/cert-manager.yaml $(ARGS)
	kubectl wait deployment -n cert-manager $(ARGS) cert-manager --for condition=Available=True --timeout=90s


.PHONY: jaeger-operator
# Install jaeger-operator
jaeger-operator:
	$(CMD) -f ./jaeger-operator/namespace.yaml $(ARGS)
	$(CMD) -f ./jaeger-operator/jaeger-operator.yaml -n observability $(ARGS)
	kubectl wait deployment -n observability $(ARGS) jaeger-operator --for condition=Available=True --timeout=90s
	

.PHONY: jaeger
# Install jaeger
jaeger:
	$(CMD) -f ./jaeger/jaeger.yaml -n observability $(ARGS)
	$(CMD) -f ./jaeger/jaeger-ui-ingress.yaml -n observability $(ARGS)

.PHONY: all
# Install all
all: cert-manager jaeger-operator jaeger

.PHONY: uninstall
# Unnstall all
uninstall: CMD=kubectl delete
uninstall: cert-manager jaeger-operator jaeger

.PHONY: update
# Update manifest
update:
	kubectl kustomize ./cert-manager > ./cert-manager/cert-manager.yaml
	kubectl kustomize ./jaeger-operator > ./jaeger-operator/jaeger-operator.yaml

.PHONY: status
# Get status
status: 
	kubectl describe ingress jaeger-ui $(ARGS) -n observability

# show help
help:
	@echo ''
	@echo 'Usage:'
	@echo ' make [target]'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
	helpMessage = match(lastLine, /^# (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 2, RLENGTH); \
			printf "\033[36m%-22s\033[0m %s\n", helpCommand,helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help
