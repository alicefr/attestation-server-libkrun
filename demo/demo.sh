#!/bin/bash

set -x
export KUBECONFIG=~/.crc/machines/crc/kubeconfig

VERSION=latest
IMAGE_SA_NAME=attestation-server
IMAGE_GEN_NAME=generate-libkrun-measurment
IMAGE_REG_NAME=register-image
LOCAL_IMAGE_AS="quay.io/$IMAGE_SA_NAME:$VERSION"
LOCAL_IMAGE_GEN="quay.io/$IMAGE_GEN_NAME:$VERSION"
LOCAL_IMAGE_REG="quay.io/$IMAGE_REG_NAME:$VERSION"
NS=attestation

# Push into the internal registry
oc login -u kubeadmin -p $(cat ~/.crc/machines/crc/kubeadmin-password) https://api.crc.testing:6443
oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
podman login -u kubeadmin -p $(oc whoami -t) --tls-verify=false $HOST 

oc new-project $NS
oc create imagestream $IMAGE_SA_NAME
oc create imagestream $IMAGE_GEN_NAME

IMAGE_SA="$HOST/$NS/$IMAGE_SA_NAME:$VERSION"
IMAGE_GEN="$HOST/$NS/$IMAGE_GEN_NAME:$VERSION"

podman tag $LOCAL_IMAGE_AS  $IMAGE_SA
podman push --tls-verify=false $IMAGE_SA
podman tag $LOCAL_IMAGE_GEN  $IMAGE_GEN
podman push --tls-verify=false $IMAGE_GEN
podman tag $LOCAL_IMAGE_REG  $IMAGE_REG
podman push --tls-verify=false $IMAGE_REG

oc apply -f ../k8s-deployment
