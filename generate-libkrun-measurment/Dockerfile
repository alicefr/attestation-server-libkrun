FROM quay.io/crun-krun as BUILD

FROM fedora:35

COPY --from=BUILD /output/usr/local/lib64/libkrunfw.so /usr/lib64/libkrunfw.so
COPY target/release/generate-libkrun-measurment /usr/bin

ENTRYPOINT ["/usr/bin/generate-libkrun-measurment"]
 
