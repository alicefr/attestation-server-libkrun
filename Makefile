CONTAINER_RUNTIME ?= podman
IMAGE_ATTEST_SERV=attestation-server
IMAGE_GEN_MES=generate-libkrun-measurment
IMAGE_REG=register-image
IMAGE_ENCRYPT=encrypt-image
IMAGE_DEBUG=debug
TAG ?= latest
REGISTRY ?= "quay.io"

build:
	cargo build

build-attester:
	cd attester
	cargo build --release

build-generate-libkrunfw-measurment:
	cd generate-libkrun-measurment
	cargo build --release

image-attestation-server: build-attester
	$(CONTAINER_RUNTIME) build -t "$(REGISTRY)/$(IMAGE_ATTEST_SERV):$(TAG)" -f attester/Dockerfile .

image-generate-libkrunfw-measurment: build-generate-libkrunfw-measurment
	$(CONTAINER_RUNTIME) build -t "$(REGISTRY)/$(IMAGE_GEN_MES):$(TAG)" -f generate-libkrun-measurment/Dockerfile .

image-register-image:
	$(CONTAINER_RUNTIME) build -t "$(REGISTRY)/$(IMAGE_REG):$(TAG)" -f register-image/Dockerfile register-image/

image-encrypt:
	$(CONTAINER_RUNTIME) build -t "$(REGISTRY)/$(IMAGE_ENCRYPT):$(TAG)" -f encrypt-image/Dockerfile encrypt-image/

image-debug:
	$(CONTAINER_RUNTIME) build -t "$(REGISTRY)/$(IMAGE_DEBUG):$(TAG)" -f debug-container/Dockerfile debug-container/

images: image-attestation-server  image-generate-libkrunfw-measurment image-register-image image-encrypt image-debug
