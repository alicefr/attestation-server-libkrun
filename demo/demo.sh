#!/bin/bash

set -x

USER=${USER:-kubeadmin}
VERSION=latest
IMAGE_SA_NAME=attestation-server
IMAGE_GEN_NAME=generate-libkrun-measurment
IMAGE_REG_NAME=register-image
IMAGE_ENCRYPT_NAME=encrypt-image
IMAGE_DEBUG_NAME=debug
LOCAL_IMAGE_AS="quay.io/$IMAGE_SA_NAME:$VERSION"
LOCAL_IMAGE_GEN="quay.io/$IMAGE_GEN_NAME:$VERSION"
LOCAL_IMAGE_REG="quay.io/$IMAGE_REG_NAME:$VERSION"
LOCAL_IMAGE_ENCRYPT="quay.io/$IMAGE_ENCRYPT_NAME"
LOCAL_IMAGE_DEBUG="quay.io/$IMAGE_DEBUG_NAME"
ATTESTATION_NS=attestation
TKN_NS=tekton-build
UNTRUSTED_NS=untrusted

# Expose the internal registry
oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
podman login -u admin -p $(oc whoami -t) --tls-verify=false $HOST

oc new-project $ATTESTATION_NS
oc create imagestream $IMAGE_SA_NAME
oc create imagestream $IMAGE_GEN_NAME

oc new-project $TKN_NS
oc create imagestream $IMAGE_REG_NAME
oc create imagestream $IMAGE_ENCRYPT_NAME

# Create untrusted ns where the encrypted image will be pushed and deployed for the demo
oc new-project $UNTRUSTED_NS

IMAGE_SA="$HOST/$ATTESTATION_NS/$IMAGE_SA_NAME:$VERSION"
IMAGE_GEN="$HOST/$ATTESTATION_NS/$IMAGE_GEN_NAME:$VERSION"
IMAGE_REG="$HOST/$TKN_NS/$IMAGE_REG_NAME:$VERSION"
IMAGE_ENCRYPT="$HOST/$TKN_NS/$IMAGE_ENCRYPT_NAME:$VERSION"
IMAGE_DEBUG="$HOST/$ATTESTATION_NS/$IMAGE_DEBUG_NAME:$VERSION"

# Copy all the images inside the internal registry
# TODO create a function to push 
podman tag $LOCAL_IMAGE_AS  $IMAGE_SA
podman push --tls-verify=false $IMAGE_SA
podman tag $LOCAL_IMAGE_GEN  $IMAGE_GEN
podman push --tls-verify=false $IMAGE_GEN
podman tag $LOCAL_IMAGE_REG  $IMAGE_REG
podman push --tls-verify=false $IMAGE_REG
podman tag $LOCAL_IMAGE_ENCRYPT  $IMAGE_ENCRYPT
podman push --tls-verify=false $IMAGE_ENCRYPT
podman tag $LOCAL_IMAGE_DEBUG  $IMAGE_DEBUG
podman push --tls-verify=false $IMAGE_DEBUG

# Give privileged ssc to the sa for the demo. TODO define stricter rules
oc adm policy add-scc-to-user privileged  system:serviceaccount:$ATTESTATION_NS:default
oc adm policy add-scc-to-user privileged  system:serviceaccount:$TKN_NS:pipeline
oc adm policy add-scc-to-user privileged  system:serviceaccount:$UNTRUSTED_NS:default

# Install tekton tasks
oc project $TKN_NS
oc apply -f ../encrypt-image/tekton-task.yaml
oc apply -f ../register-image/tekton-task.yaml

# Deploy the attestation server and expose the service
oc project $ATTESTATION_NS
oc apply -f ../k8s-deployment
