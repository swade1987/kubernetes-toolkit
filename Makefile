APP_NAME=kubernetes-toolkit

QUAY_REPO=swade1987
QUAY_USERNAME?="swade1987+kubernetes_toolkit"
QUAY_PASSWORD?="unknown"

KUBERNETES_VERSION=1.17.2
IMAGE = quay.io/$(QUAY_REPO)/$(APP_NAME):$(KUBERNETES_VERSION)

build:
	clear
	docker build \
	--build-arg KUBERNETES_VERSION=$(KUBERNETES_VERSION) \
	-t $(IMAGE) .

login:
	docker login -u $(QUAY_USERNAME) -p $(QUAY_PASSWORD) quay.io

logout:
	docker logout

push:
	docker push $(IMAGE)
	docker rmi $(IMAGE)
