#!/bin/bash -x

IP=$(sudo podman container inspect --format '{{ .NetworkSettings.IPAddress }}' attestation-server)
sudo  podman run -ti --runtime /usr/local/bin/crun \
       -m 3072M \
       --device /dev/kvm \
       --device /dev/sev \
       --volume /tmp/libkrun-sev.chain:/tmp/libkrun-sev.chain \
       --entrypoint "/entrypoint.sh" \
       --annotation run.oci.handler="krun" \
       --annotation krun/attestation="http://$IP:8081/untrusted" \
       --annotation krun/image="localhost/fedora-encrypt-luks1@sha256:6c4bec5d6ad2c3deff4c4a59f10188bb3d6cc1033d0d603b4d08ee67d7a449aa" \
       fedora-encrypt-luks1
