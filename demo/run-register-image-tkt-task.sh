#!/bin/bash

# Run the tekton task for encrypting the image
tkn task  start register-encrypt-image -p image=fedora:latest \
        -p cmd="/bin/bash" \
	-p image_reg_svc="registration-attestation-server/register-image" \
	-p namespace="attestation" \
        --use-param-defaults \
        -p password=myamazingpassword \

