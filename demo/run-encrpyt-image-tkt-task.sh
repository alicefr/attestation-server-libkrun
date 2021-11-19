#!/bin/bash

OUTPUT_NS=untrusted
# Create untrusted ns where the encrypted image will be deployed for the demo
oc new-project $OUTPUT_NS

SA=tekton-encryp-images
REGISTRY=image-registry.openshift-image-registry.svc:5000
# Run the tekton task for encrypting the image
tkn task  start encrypt-image -p input-image=fedora:latest \
        -p output-image="$REGISTRY/$OUTPUT_NS/demo-encrypted-image:latest" \
        --use-param-defaults \
	-p namespace-tekton-task="attestation" \
        -p password=myamazingpassword \
	-p user=kubeadmin -p reg-password=$(oc whoami -t)  -s $SA

