FROM fedora:35 as BUILD

RUN dnf install -y \
   bison \
   bc \
   curl \
   elfutils-libelf-devel \
   findutils \
   flex \
   gcc \
   git \
   make \
   openssl-devel \
   patch \
   python3 \
   python3-pyelftools \
   tar \
   xz  \
   diffutils \
   && rm -rf /var/cache /var/log/dnf* /var/log/yum.*

 
RUN git clone -b amdsev https://github.com/containers/libkrunfw.git  \
    && cd libkrunfw \
    && make 

FROM fedora:35

COPY --from=BUILD /libkrunfw/libkrunfw.so /usr/lib64/libkrunfw.so
COPY target/release/generate-libkrun-measurment /usr/bin

ENTRYPOINT ["/usr/bin/generate-libkrun-measurment"]
 
