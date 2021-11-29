#!/bin/bash

SA=tekton-encryp-images
oc policy add-role-to-user system:image-puller system:serviceaccount:attestation:$SA -n untrusted
# Run the tekton task for encrypting the image
tkn task  start register-encrypt-image -p image="image-registry.openshift-image-registry.svc:5000/untrusted/demo-encrypted-image:latest" \
        -p cmd="/bin/bash" \
	-p image_reg_svc="registration-attestation-server:8080/confidential/register-image" \
	-p namespace="attestation" \
        --use-param-defaults \
        -p password=myamazingpassword \
	-s $SA
