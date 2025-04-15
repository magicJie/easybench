REGISTRY ?= 
ORG ?= 
REPO ?= easybench
ARCH ?=
IMAGE_TAG ?= latest
IMAGE_NAME := $(REPO)$(if $(ARCH),_$(ARCH))
IMAGE_FULL_NAME := $(if $(REGISTRY),$(REGISTRY)/)$(if $(ORG),$(ORG)/)$(IMAGE_NAME):$(IMAGE_TAG)
OCI ?= "podman"

CMD ?= '--help'
SERVER ?= "127.0.0.1"

# 默认目标（显示帮助信息）
.DEFAULT_GOAL := help

print:
	@echo "IMAGE_FULL_NAME is $(IMAGE_FULL_NAME)"

# 帮助信息
.PHONY: help
help:
	@echo "可用命令:"
	@echo "  make build              # 构建 $(OCI) 镜像（默认开发环境）"
	@echo "  make clean              # 删除镜像和容器"
	@echo "  make help               # 显示此帮助信息"
	@echo "  make load               # 从文件加载镜像"
	@echo "  make push               # 推送镜像到镜像仓库"
	@echo "  make run                # 运行容器,开发模式，挂载代码"
	@echo "  make run-prod           # 运行容器,生产模式"
	@echo "  make save               # 保存镜像到文件"
	@echo "  make test-cpu           # cpu测试"
	@echo "  make test-fileio        # 文件读写测试"
	@echo "  make test-mem           # 内存测试"
	@echo "  make test-net           # 网络测试"
	@echo "  make test-net-server    # 启动网络测试服务端"

.PHONY: build
build:
	$(OCI) build -t $(IMAGE_FULL_NAME) .

.PHONY: run
run:
	$(OCI) run --replace --rm -it -v $(CURDIR)/work:/root/work --name $(IMAGE_NAME) $(IMAGE_FULL_NAME) bash

# 清理镜像和容器
.PHONY: clean
clean: 
	$(OCI) rmi $(IMAGE_FULL_NAME) || true

# cpu测试
test-cpu:
	$(OCI) run --rm --name $(IMAGE_NAME) $(IMAGE_FULL_NAME) \
		sysbench cpu --time=60 --threads=8 --report-interval=2 --cpu-max-prime=20000 run
# 内存测试
test-mem:
	$(OCI) run --rm --name $(IMAGE_NAME) $(IMAGE_FULL_NAME) \
		sysbench memory --threads=8 --report-interval=2 --memory-block-size=8k --memory-total-size=100G --memory-access-mode=seq run
# 文件随机读写测试
test-fileio:
	@if [ ! -d $(CURDIR)/work ]; then \
		mkdir -p $(CURDIR)/work; \
		else \
		rm -rf $(CURDIR)/work/*; \
	fi
	$(OCI) run -v $(CURDIR)/work:/root/work --rm --privileged --name $(IMAGE_NAME) $(IMAGE_FULL_NAME) \
		sysbench fileio --threads=8 --report-interval=2 --file-num=2 --file-total-size=4G --file-test-mode=rndrw prepare
	$(OCI) run -v $(CURDIR)/work:/root/work --rm --privileged --name $(IMAGE_NAME) $(IMAGE_FULL_NAME) \
		sysbench fileio --threads=8 --report-interval=2 --file-num=2 --file-total-size=4G --file-test-mode=rndrw run
	$(OCI) run -v $(CURDIR)/work:/root/work --rm --privileged --name $(IMAGE_NAME) $(IMAGE_FULL_NAME) \
		sysbench fileio --threads=8 --report-interval=2 --file-num=2 --file-total-size=4G --file-test-mode=rndrw cleanup
# 线程测试
test-threads:
	$(OCI) run --rm --name $(IMAGE_NAME) $(IMAGE_FULL_NAME) \
		sysbench threads --threads=8 --thread-yield-count=1000000 run
# 互斥测试
test-mutex:
	$(OCI) run --rm --name $(IMAGE_NAME) $(IMAGE_FULL_NAME) \
		sysbench mutex --mutex-type=spinlock run
# 网络测试（服务端），为了避免网络损失，使用host网络
test-net-server:
	$(OCI) run --rm --name $(IMAGE_NAME)-server --network=host $(IMAGE_FULL_NAME) \
		iperf3 -s
# 网络测试
test-net:
	$(OCI) run --rm --name $(IMAGE_NAME) --network=host $(IMAGE_FULL_NAME) \
		iperf3 -P 8 -i 5 -5 60 -c $(SERVER)
# 自定义测试
test:
	$(OCI) run --rm --name $(IMAGE_NAME) $(IMAGE_FULL_NAME) \
		sysbench $(CMD)

# 推送镜像到镜像仓库
.PHONY: push
push:
	$(OCI) push $(IMAGE_FULL_NAME)

# 保存镜像到文件
.PHONY: save
save:
	@if [ ! -d $(CURDIR)/out ]; then \
			mkdir -p $(CURDIR)/out; \
		else \
			rm -rf $(CURDIR)/out/*; \
	fi
	$(OCI) image save -o out/$(IMAGE_NAME).tar $(IMAGE_FULL_NAME)
	zip -7 out/$(IMAGE_NAME).zip out/$(IMAGE_NAME).tar

# 从文件加载镜像
.PHONY: load
load:
	unzip out/$(IMAGE_NAME).zip out/$(IMAGE_NAME).tar
	$(OCI) image load -i out/$(IMAGE_NAME).tar
