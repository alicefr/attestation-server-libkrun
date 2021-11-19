#!/bin/bash

VOL_MEASURM=librunfw-measurment
VOL_IMAGE_REPO=image-repository

podman volume create ${VOL_MEASURM}
podman volume create ${VOL_IMAGE_REPO}

podman run -ti -v ${VOL_MEASURM}:/var/lib/attestation-server/measurments \
	--name generate-libkrun-measurment \
	quay.io/generate-libkrun-measurment \
       	-d /var/lib/attestation-server/measurments

podman run -td -v ${VOL_MEASURM}:/var/lib/attestation-server/measurments \
	${VOL_IMAGE_REPO}:/var/lib/attestation-server/registered-images.json \
	--name attestation-server \
	-p 8080:8080 -p 8081:8081 \
	quay.io/attestation-server \
	-d /var/lib/attestation-server/measurments -i /var/lib/attestation-server/registered-images.json

