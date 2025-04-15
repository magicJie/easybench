# 快速开始

```bash
git clone https://github.com/magicJie/easybench.git
cd easybench

# 构建镜像
make build

# 测试
make test-cpu
make test-mem
make test-fileio
make test-network
make test-thread
```

# 网络测试

## 启动网络测试服务端

```bash
make test-net-server
```

## 启动网络测试客户端

```bash
SERVER=172.16.1.1 make test-net
```