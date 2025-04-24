PROJNAME := kubernetes-toolkit
KUBERNETES_VERSION := 1.33.0
GOOS ?= $(if $(TARGETOS),$(TARGETOS),linux)
GOARCH ?= $(if $(TARGETARCH),$(TARGETARCH),amd64)
BUILDPLATFORM ?= $(GOOS)/$(GOARCH)

# ############################################################################################################
# Local tasks
# ############################################################################################################

initialise:
	pre-commit --version || brew install pre-commit
	pre-commit install --install-hooks
	pre-commit run -a

build:
	docker buildx build --build-arg BUILDPLATFORM=$(BUILDPLATFORM) --build-arg TARGETARCH=$(GOARCH) \
	--build-arg KUBERNETES_VERSION=$(KUBERNETES_VERSION) \
	-t local/$(PROJNAME):$(KUBERNETES_VERSION) .

scan: build
	trivy --light -s "UNKNOWN,MEDIUM,HIGH,CRITICAL" --exit-code 1 local/$(PROJNAME):$(KUBERNETES_VERSION)
