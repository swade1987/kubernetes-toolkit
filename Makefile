CURRENT_WORKING_DIR=$(shell pwd)

KUBERNETES_VERSION		:= 1.17.2

#------------------------------------------------------------------
# Project build information
#------------------------------------------------------------------
PROJNAME          		:= kubernetes-toolkit
VENDOR            		:= swade1987

QUAY_REPO         		:= quay.io/swade1987
QUAY_USERNAME     		:= "swade1987+kubernetes_toolkit"
QUAY_PASSWORD     		?="unknown"

IMAGE             		:= $(PROJNAME):$(KUBERNETES_VERSION)

#------------------------------------------------------------------
# CI targets
#------------------------------------------------------------------

build:
	docker build \
    --build-arg git_repository=`git config --get remote.origin.url` \
    --build-arg git_branch=`git rev-parse --abbrev-ref HEAD` \
    --build-arg git_commit=`git rev-parse HEAD` \
    --build-arg built_on=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
    --build-arg KUBERNETES_VERSION=$(KUBERNETES_VERSION) \
    -t $(IMAGE) .

push-to-quay:
	docker login -u $(QUAY_USERNAME) -p $(QUAY_PASSWORD) quay.io
	docker tag $(IMAGE) $(QUAY_REPO)/$(IMAGE)
	docker push $(QUAY_REPO)/$(IMAGE)
	docker rmi $(QUAY_REPO)/$(IMAGE)
	docker logout

scan: build
	trivy --light -s "UNKNOWN,MEDIUM,HIGH,CRITICAL" --exit-code 1 $(IMAGE)
