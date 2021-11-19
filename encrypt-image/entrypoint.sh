#!/bin/bash

IMAGE=$1
ENCRYPT_IMAGE=$2
PASSWORD=$3

OUTPUT=disk.img
CONT=temporary-container
OUTDIR=/tmp/output
DISK=$OUTDIR/$OUTPUT

buildah rm $CONT

set -xe 

mkdir -p $OUTDIR
buildah from --name $CONT $IMAGE
dir=$(buildah mount $CONT)
cd $dir
find . | cpio -o -c -R root:root | gzip -9 >  $DISK
# encrypt the image with the LUKS passphrase
DEVICE=$(losetup  -f  --show $DISK)
echo "YES" | echo "$PASSWORD" | cryptsetup -y -v --type luks2 luksFormat $DEVICE
losetup -d $DEVICE
buildah rm $CONT


# TODO generate fake entrypoint

# Create final image
buildah from --name $CONT scratch 
buildah copy $CONT $DISK /
# TODO copy fake entrypoint in the final image
buildah commit --rm $CONT $ENCRYPT_IMAGE
