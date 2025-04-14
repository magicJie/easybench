FROM ubuntu:xenial AS base
RUN apt-get update &&\
    apt-get -y install make automake libtool pkg-config libaio-dev git iperf3 &&\
    apt-get clean

FROM base
# 安装sysbench
RUN git clone -b dev https://github.com/magicJie/sysbench.git sysbench &&\
    cd sysbench &&\
    ./autogen.sh &&\
    ./configure --without-mysql --without-postgresql &&\
    make -j &&\
    make install
RUN rm -rf sysbench
COPY README*.md Makefile /root/
# 为了避免“双写入”导致io性能损失，预留工作目录以进行挂载
WORKDIR /root/work

EXPOSE 5201

CMD ["/bin/bash","-c","cat /root/README.md"]