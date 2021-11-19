#!/bin/bash

set -x
export KUBECONFIG=~/.crc/machines/crc/kubeconfig

VERSION=latest
IMAGE_SA_NAME=attestation-server
IMAGE_GEN_NAME=generate-libkrun-measurment
IMAGE_REG_NAME=register-image
IMAGE_ENCRYPT_NAME=encrypt-image
LOCAL_IMAGE_AS="quay.io/$IMAGE_SA_NAME:$VERSION"
LOCAL_IMAGE_GEN="quay.io/$IMAGE_GEN_NAME:$VERSION"
LOCAL_IMAGE_REG="quay.io/$IMAGE_REG_NAME:$VERSION"
LOCAL_IMAGE_ENCRYPT="quay.io/$IMAGE_ENCRYPT_NAME"
NS=attestation
INSECURE_NS=untrusted
SA=tekton-encryp-images

# Expose the internal registry
oc login -u kubeadmin -p $(cat ~/.crc/machines/crc/kubeadmin-password) https://api.crc.testing:6443
oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
podman login -u kubeadmin -p $(oc whoami -t) --tls-verify=false $HOST 

oc new-project $NS
oc create imagestream $IMAGE_SA_NAME
oc create imagestream $IMAGE_GEN_NAME
oc create imagestream $IMAGE_REG_NAME
oc create imagestream $IMAGE_ENCRYPT_NAME

IMAGE_SA="$HOST/$NS/$IMAGE_SA_NAME:$VERSION"
IMAGE_GEN="$HOST/$NS/$IMAGE_GEN_NAME:$VERSION"
IMAGE_REG="$HOST/$NS/$IMAGE_REG_NAME:$VERSION"
IMAGE_ENCRYPT="$HOST/$NS/$IMAGE_ENCRYPT_NAME:$VERSION"

# Copy all the images inside the internal registry
podman tag $LOCAL_IMAGE_AS  $IMAGE_SA
podman push --tls-verify=false $IMAGE_SA
podman tag $LOCAL_IMAGE_GEN  $IMAGE_GEN
podman push --tls-verify=false $IMAGE_GEN
podman tag $LOCAL_IMAGE_REG  $IMAGE_REG
podman push --tls-verify=false $IMAGE_REG
podman tag $LOCAL_IMAGE_ENCRYPT  $IMAGE_ENCRYPT
podman push --tls-verify=false $IMAGE_ENCRYPT

# Create setup for the encrypt images tekton task
oc apply -f ../encrypt-image/security-context.yaml
# The service accout is required to provide privileged to the encryp images task in order to be able to create the loopback disk and use cryptesetup
oc create sa $SA
oc adm policy add-scc-to-user scc-admin-demo  system:serviceaccount:$NS:$SA

# Install tekton tasks
oc apply -f ../encrypt-image/tekton-task.yaml
oc apply -f ../register-image/tekton-task.yaml

# Deploy the attestation server and expose the service
oc apply -f ../k8s-deployment

# Create untrusted ns where the encrypted image will be deployed for the demo
oc new-project $INSECURE_NS

# TODO start the buiding tekton pipeline. The pipeline builds the container image from source using s2i, it encrypts the image and it register it to the attestation server

# TODO deploy the encrypted image on the sev node
