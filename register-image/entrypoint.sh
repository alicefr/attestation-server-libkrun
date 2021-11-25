#!/bin/bash

set -x

image=$1
password=$2
cmd=$3
image_reg_svc=$4
CPUS=${CPUS:-2}
RAM=${RAM:-512}

buildah images $image || buildah pull $image

sha=$(buildah inspect --format='{{.FromImageDigest}}' $image)
prolog_kernel="reboot=k panic=-1 panic_print=0 pci=off nomodules console=hvc0 quiet rw no-kvmapf init=/bin/sh virtio_mmio.device=4K@0xd0000000:5 virtio_mmio.device=4K@0xd0001000:6 virtio_mmio.device=4K@0xd0002000:7 virtio_mmio.device=4K@0xd0003000:8 swiotlb=65536 KRUN_WORKDIR=/"

kernel_cmdline="KRUN_CFG=$CPUS:$RAM $prolog_kernel KRUN_PASS=$password KRUN_INIT=$3"

curl -X POST $image_reg_svc \
   -H 'Content-Type: application/json' \
   -d "{\"sha\":\"$sha\", \"name\":\"$image\", \"kernel_cmd_line\":\"$kernel_cmdline\" }"
