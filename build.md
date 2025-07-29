# 多架构容器镜像构建指南

本文档详细说明如何使用 `build.sh` 脚本来构建和发布多架构容器镜像。

## 前提条件

- 已安装 Docker 19.03 或更高版本
- 已安装 Docker Buildx（Docker Desktop 默认包含）
- 如果要推送到 Docker Hub，需要有效的 Docker Hub 账户

## 脚本功能

`build.sh` 脚本提供以下功能：

- 构建多平台容器镜像（支持 Linux/amd64、Linux/arm64 等）
- 自动创建和管理 Docker Buildx 构建器
- 支持推送到 Docker Hub
- 灵活的配置选项

## 基本用法

### 1. 显示帮助信息

```bash
./build.sh --help
```

### 2. 构建多平台镜像（不推送）

```bash
./build.sh --username xmx0632 \
           --image ai-terminal-home \
           --tag 1.0.0
```

### 3. 构建并推送到 Docker Hub

```bash
./build.sh --username xmx0632 \
           --image ai-terminal-home \
           --tag 1.0.0 \
           --push
```

## 命令说明

### 构建命令

```
./build.sh [选项] [命令]
```

### 可用命令

| 命令 | 参数 | 描述 |
|------|------|------|
| `build` | 无 | 构建镜像（默认命令） |
| `update-latest` | `<tag>` | 更新 latest 标签指向指定的版本 |

### 构建选项

| 参数 | 缩写 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| `--username` | `-u` | 推送时必填 | `xmx0632` | Docker Hub 用户名 |
| `--image` | `-i` | 否 | `ai-terminal-home` | 镜像名称 |
| `--tag` | `-t` | 否 | `latest` | 镜像标签 |
| `--platforms` | `-p` | 否 | `linux/amd64,linux/arm64` | 目标平台，逗号分隔 |
| `--push` | 无 | 否 | `false` | 推送到 Docker Hub |
| `--build-only` | 无 | 否 | `false` | 仅构建镜像，不推送到仓库 |
| `--output` | `-o` | 否 | `build_output` | 构建输出目录 |
| `--help` | `-h` | 否 | 无 | 显示帮助信息 |

## 使用示例

### 1. 构建镜像

#### 仅构建不推送
```bash
# 构建多平台镜像并保存到本地 Docker 镜像
./build.sh -i ai-terminal-home -t 1.0.0 --build-only

# 查看已构建的镜像
docker images | grep ai-terminal-home

# 查看特定平台的镜像
docker image inspect xmx0632/ai-terminal-home:1.0.0-linux-amd64

# 构建并导出为 tar 文件（用于离线部署）
./build.sh -i ai-terminal-home -t 1.0.0 --build-only -o /path/to/output/dir

# 在目标机器上加载镜像
docker load -i /path/to/output/dir/ai-terminal-home-1.0.0-linux-amd64.tar
docker load -i /path/to/output/dir/ai-terminal-home-1.0.0-linux-arm64.tar
```

#### 构建并推送
```bash
# 构建并推送到 Docker Hub
./build.sh -i ai-terminal-home -t 1.0.0 --push
```

### 2. 更新 latest 标签

```bash
# 将 latest 标签指向 1.0.0 版本
./build.sh update-latest 1.0.0

# 指定镜像名称
./build.sh -i ai-terminal-home update-latest 1.0.0

# 指定 Docker Hub 用户名
./build.sh -u xmx0632 update-latest 1.0.0
```

### 3. 分步操作：先构建后推送

```bash
# 1. 先构建镜像并保存到本地 Docker
./build.sh -i ai-terminal-home -t 1.0.0 --build-only

# 2. 推送指定平台的镜像到 Docker Hub
docker push xmx0632/ai-terminal-home:1.0.0-linux-amd64
docker push xmx0632/ai-terminal-home:1.0.0-linux-arm64

# 3. 创建多架构清单并推送
# 首先创建并推送每个平台的清单
docker manifest create xmx0632/ai-terminal-home:1.0.0 \
    --amend xmx0632/ai-terminal-home:1.0.0-linux-amd64 \
    --amend xmx0632/ai-terminal-home:1.0.0-linux-arm64

# 推送清单到 Docker Hub
docker manifest push xmx0632/ai-terminal-home:1.0.0

# 4. 更新 latest 标签
./build.sh update-latest 1.0.0
```

### 示例 3：自定义平台

```bash
# 构建特定平台的镜像
./build.sh -u xmx0632 \
           -i ai-terminal-home \
           -t 1.0.0 \
           -p linux/amd64,linux/arm64,linux/arm/v7 \
           --push
```

### 示例 4：使用默认值

```bash
# 使用默认镜像名称和标签
./build.sh -u xmx0632 --push
```

## 构建器管理

### 1. 查看构建器状态

```bash
docker buildx ls
```

### 2. 检查构建器详情

```bash
docker buildx inspect mybuilder
```

### 3. 删除构建器

```bash
docker buildx rm mybuilder
```

## 验证构建结果

### 1. 查看本地镜像

```bash
# 查看所有本地镜像
docker images | grep ai-terminal-home

# 查看特定平台的镜像详情
docker image inspect xmx0632/ai-terminal-home:1.0.0-linux-amd64

# 查看多架构镜像清单（如果已创建）
docker manifest inspect xmx0632/ai-terminal-home:1.0.0
```

### 2. 在 Docker Hub 上查看

登录 [Docker Hub](https://hub.docker.com/)，进入你的仓库页面，检查镜像标签下的多架构支持情况。

## 常见问题

### 1. 构建失败："no match for platform"

确保你的 Docker 环境支持所选的平台。要查看当前支持的所有平台，可以运行：

```bash
docker buildx inspect --bootstrap
```

### 2. 推送失败："denied: requested access to the resource is denied"

确保已登录 Docker Hub：

```bash
docker login
```

### 3. 构建过程很慢

构建多平台镜像可能会很耗时，特别是在模拟不同架构时。考虑：

- 使用原生架构的构建服务器
- 减少不必要的构建步骤
- 使用多阶段构建来减小最终镜像大小

## 最佳实践

1. **使用语义化版本**：遵循 [语义化版本](https://semver.org/) 规范来标记镜像
2. **定期更新基础镜像**：确保使用最新的安全补丁
3. **使用多阶段构建**：减小最终镜像大小
4. **扫描安全漏洞**：使用 `docker scan` 检查镜像中的已知漏洞

## 集成到 CI/CD 流程

以下是一个 GitHub Actions 工作流示例，用于自动构建和推送多平台镜像：

```yaml
name: Build and Push Multi-arch Images

on:
  push:
    tags:
      - 'v*'  # 推送标签时触发

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push
        run: |
          ./build.sh \
            --username ${{ secrets.DOCKERHUB_USERNAME }} \
            --image ai-terminal \
            --tag ${GITHUB_REF#refs/tags/v} \
            --push
```

## 注意事项

1. 构建 Windows 容器需要额外的配置，请参考 [Docker 文档](https://docs.docker.com/build/building/multi-platform/)
2. 在 CI/CD 环境中使用时，请妥善保管 Docker Hub 凭据
3. 构建多平台镜像会消耗较多系统资源，建议在性能较好的机器上执行
