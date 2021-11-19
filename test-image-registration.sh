#!/bin/bash
set -xe

curl -X POST 0.0.0.0:8080/confidential/register-image \
	-H 'Content-Type: application/json'  \
	-d '{"sha":"sha256:c048d487eebf8ab71dd262aae1816ed6c4343628802de086079a879ca6d6c5fa", "name":"fedora:latest", "kernel_cmd_line":"KRUN_CFG=2:512 reboot=k panic=-1 panic_print=0 pci=off nomodules console=hvc0 quiet rw no-kvmapf init=/bin/sh virtio_mmio.device=4K@0xd0000000:5 virtio_mmio.device=4K@0xd0001000:6 virtio_mmio.device=4K@0xd0002000:7 virtio_mmio.device=4K@0xd0003000:8 swiotlb=65536 KRUN_WORKDIR=/ KRUN_PASS=myamazingpassword KRUN_INIT=/bin/bash -- \\0" }'
