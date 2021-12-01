# Generate libkrun measurment

The generate-libkrun-measurment generates the measurment for the installed libkrunfw libraries. This measurment in used by the attestation server in order to validate the runtime during the attestation phase.
You can use the [containerized environment](https://github.com/alicefr/attestation-server/tree/main/build-libkrun-crun-sev) to build the libkrunfw library, generate the measurment and install it in your system. 
In this way, the versions of the library matches.
