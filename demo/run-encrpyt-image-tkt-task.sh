#!/bin/bash

SA=tekton-encryp-images
OUTPUT_NS=
# Run the tekton task for encrypting the image
tkn task  start encrypt-image -p input-image=fedora:latest \
        -p output-image="$INSECURE_NS/demo-encrypted-image:latest" \
        --use-param-defaults \
	-p namespace-tekton-task="attestation" \
        -p password=myamazingpassword \
	-p user=kubeadmin -p reg-password=$(oc whoami -t)  -s $SA

