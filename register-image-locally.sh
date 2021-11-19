#!/bin/bash

set -xe 

IMAGE=localhost/encrypt
PASS=myamazingpassword
CMD="/bin/sh"
SVC=localhost:8080/confidential/register-image
podman run --network host -it --security-opt label=disable -v $HOME/.local/share/containers:/var/lib/containers \
	quay.io/register-image	\
	$IMAGE $PASS $CMD $SVC
