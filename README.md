# 建议复制 Makefile 到本地，然后参考 Makefile 快速开始

```bash
podman create --name sysbench swr.lan.aiminjie.com/amj/sysbench_x64:latest
podman cp sysbench:/root/Makefile .
podman rm -f sysbench

```

# 快速开始

```bash
make

make test-cpu
make test-mem
make test-fileio
make test-network
make test-thread

# 或直接运行所有测试
make test-all

启动网络测试服务端
make test-net-server

SERVER=172.16.1.1 make test-net
```

# 如果环境不支持使用 make，复制相关命令到终端运行即可
