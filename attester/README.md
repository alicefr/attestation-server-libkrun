# The Attester

The attester is a trusted service responsible for attesting the runtime and to reply with the encrypted secret. The secret consists in the kernel command line used to boot the confidential VM with libkrun.
The kernel command line contains the confidential information to decrypt the encrypted image and the process information to be run in the confidential VM.

The confidential information are registered in clear in a previous together with the image. In order to identify the image and secret, the runtime needs to inform the attestation server by providing the image name and sha.

The attestetation server has 2 endpoint:
  - `confidential`: where the images and likbrun measurments are registered
  - `untrused`: where the runtime can be attested
