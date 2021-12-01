# Attestation server and setup to deploy confidential workloads on k8s

This repository contains the setup and scripts to deploy in k8s/Openshift the various components for:
  * Attestation server for the encrypted image registration and confidential computing attestation using [libkrun](https://github.com/containers/libkrun)
  * Building the encrypted images to be used by libkrun
  * The [tekton](https://tekton.dev/) tasks for building the encrypted images and register the encrypted image

The picture illustrates the architecture and how the components interact between each other
![architecture](pictures/CW-flow.png)

For more information about the libkrun extention for SEV support reference the presentation [Don't peek into my container!](https://static.sched.com/hosted_files/kvmforum2021/44/Dont_Peek_Into_my_Container.pdf), the [recordings](https://www.youtube.com/watch?v=ww6EiDsCRz4) and the [virtee home page](https://virtee.io/).
