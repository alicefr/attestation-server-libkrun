# Create encrypted image for Confidential workloads

## Build
```
$ podman build -t quay.io/encrypt-image -f image/Dockerfile
```

## RUN
Locally in a separate directory
```bash
$ sudo mkdir -p /var/lib/containers1 
$ sudo podman run --privileged -it -v /var/lib/containers1:/var/lib/containers:Z quay.io/encrypt-image fedora:latest  fedora:latest encrypt myamazingpassword
$ sudo podman --root /var/lib/containers1/storage images  -a
REPOSITORY                         TAG         IMAGE ID      CREATED         SIZE
localhost/encrypt                  latest      44d10fe62130  16 minutes ago  3.25 kB
<none>                             <none>      4ae8fc7c1659  21 minutes ago  3.25 kB
registry.fedoraproject.org/fedora  latest      1b52edb08181  16 hours ago    159 MB
```

Run the encrypt imge task standalone:
```bash
$ cd ../demo
$ ./run-encrpyt-image-tkt-task.sh
```
