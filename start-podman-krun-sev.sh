#!/bin/bash -x

IP=$(sudo podman container inspect --format '{{ .NetworkSettings.IPAddress }}' attestation-server)
sudo podman run -ti --runtime /usr/local/bin/crun \
       --device /dev/kvm \
       --device /dev/sev \
       --ulimit memlock=4294967296:4294967296 \
       --volume /tmp/libkrun-sev.chain:/tmp/libkrun-sev.chain \
       --runtime-flag "debug" \
       --entrypoint "/entrypoint.sh" \
       --annotation run.oci.handler="krun" \
       --annotation krun/attestation="http://$IP:8081/untrusted" \
       --annotation krun/image="fedora-encrypt-luks1@sha256:a879b1f277c04b03ac912980aa9b3a2562a2f4fcbc5c8606c58b0fa40d93ec57" \
       fedora-encrypt-luks1

