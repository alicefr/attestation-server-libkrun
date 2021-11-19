#!/bin/bash

DIR=$HOME/libkrunfw-lib

mkdir -p $DIR
podman create --name lib quay.io/generate-libkrun-measurment
podman cp lib:/usr/lib64/libkrunfw.so $DIR
podman rm lib

echo "ADD $DIR to LD_LIBRARY_PATH"
