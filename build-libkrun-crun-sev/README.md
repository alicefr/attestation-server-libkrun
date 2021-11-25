# Build of libkrun and crun with SEV support

```bash
§ podman build -t crun-krun -f build-libkrun-crun-sev/Dockerfile .
$ podman export -o crun-krun.tar $(podman create localhost/crun-krun /)
$ mkdir -p /tmp/extract-output
$ tar -xf crun-krun.tar -C /tmp/extract-output
```
