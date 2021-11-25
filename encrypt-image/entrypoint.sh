#!/bin/bash -x

IMAGE=$1
ENCRYPT_IMAGE=$2
PASSWORD=$3

OUTPUT=disk.img
CONT=temporary-container
OUTDIR=/tmp/output
ROOT_DIR=/tmp/rootfs
DISK=$OUTDIR/$OUTPUT
DISK_SIZE=1G
CRYPT_PARTITION=root

buildah rm $CONT
cryptsetup luksClose $CRYPT_PARTITION
rm $DISK
set -e

mkdir -p $OUTDIR $ROOT_DIR
fallocate -l $DISK_SIZE $DISK
# encrypt the image with the LUKS passphrase
DEVICE=$(losetup  -f  --show $DISK)
echo "YES" | echo "$PASSWORD"| cryptsetup luksFormat -y -v --type luks1 $DEVICE
echo "$PASSWORD" | cryptsetup luksOpen $DEVICE $CRYPT_PARTITION
mkfs.ext4 /dev/mapper/$CRYPT_PARTITION
mount /dev/mapper/$CRYPT_PARTITION $ROOT_DIR
buildah from --name $CONT $IMAGE
dir=$(buildah mount $CONT)
cd $dir
cp -r * $ROOT_DIR
# Clean up
umount $ROOT_DIR
cryptsetup luksClose $CRYPT_PARTITION
losetup -d $DEVICE
buildah rm $CONT


# generate fake entrypoint
touch $OUTDIR/entrypoint.sh
chmod +x $OUTDIR/entrypoint.sh

# Create final image
buildah from --name $CONT scratch 
buildah copy $CONT $DISK /
buildah copy $CONT $OUTDIR/entrypoint.sh /
buildah commit --rm $CONT $ENCRYPT_IMAGE
