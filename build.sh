#!/bin/bash

# 多架构容器镜像构建脚本
# 该脚本使用 Docker Buildx 构建并推送多平台容器镜像

set -e  # 遇到错误时退出

# 默认配置
DOCKER_USERNAME="xmx0632"
IMAGE_NAME="ai-terminal-home"
TAG="latest"
PLATFORMS="linux/amd64,linux/arm64"  # 默认构建 amd64 和 arm64 架构
PUSH_TO_HUB=false
BUILD_ONLY=false
BUILDER_NAME="mybuilder"
OUTPUT_DIR="build_output"  # 用于保存构建输出的目录

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项] [命令]"
    echo "命令:"
    echo "  build                构建镜像 (默认命令)"
    echo "  update-latest <tag>  更新 latest 标签指向指定的版本"
    echo ""
    echo "选项:"
    echo "  -u, --username    Docker Hub 用户名 (默认: ${DOCKER_USERNAME})"
    echo "  -i, --image       镜像名称 (默认: ${IMAGE_NAME})"
    echo "  -t, --tag         镜像标签 (默认: ${TAG})"
    echo "  -p, --platforms   目标平台，逗号分隔 (默认: ${PLATFORMS})"
    echo "  --push            推送到 Docker Hub (需要先登录)"
    echo "  --build-only      仅构建镜像，不推送到仓库"
    echo "  -o, --output      构建输出目录 (默认: ${OUTPUT_DIR})"
    echo "  -h, --help        显示此帮助信息"
    exit 0
}

# 解析命令
COMMAND="build"
if [[ "$1" =~ ^(build|update-latest)$ ]]; then
    COMMAND="$1"
    shift
    if [ "$COMMAND" = "update-latest" ]; then
        if [ -z "$1" ] || [[ "$1" == -* ]]; then
            echo "错误: update-latest 命令需要一个版本号参数"
            exit 1
        fi
        TARGET_VERSION="$1"
        shift
    fi
fi

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        -u|--username)
            DOCKER_USERNAME="$2"
            shift 2
            ;;
        -i|--image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -p|--platforms)
            PLATFORMS="$2"
            shift 2
            ;;
        --push)
            PUSH_TO_HUB=true
            shift
            ;;
        --build-only)
            BUILD_ONLY=true
            shift
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "错误: 未知选项 $1"
            show_help
            exit 1
            ;;
    esac
done

# 检查必要参数
if [ -z "$DOCKER_USERNAME" ] && [ "$PUSH_TO_HUB" = true ]; then
    echo "错误: 推送到 Docker Hub 需要指定用户名"
    show_help
    exit 1
fi

# 设置完整镜像名称
FULL_IMAGE_NAME="${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"

# 更新 latest 标签
update_latest_tag() {
    local version="$1"
    echo "🔄 正在更新 latest 标签指向版本: $version"
    
    # 登录 Docker Hub
    echo "🔑 登录到 Docker Hub..."
    docker login || { echo "❌ Docker 登录失败"; exit 1; }
    
    # 拉取指定版本的镜像
    echo "⬇️  拉取镜像 ${DOCKER_USERNAME}/${IMAGE_NAME}:${version}"
    docker pull "${DOCKER_USERNAME}/${IMAGE_NAME}:${version}" || {
        echo "❌ 无法拉取镜像 ${DOCKER_USERNAME}/${IMAGE_NAME}:${version}"
        exit 1
    }
    
    # 标记为 latest
    echo "🏷️  标记为 latest..."
    docker tag "${DOCKER_USERNAME}/${IMAGE_NAME}:${version}" "${DOCKER_USERNAME}/${IMAGE_NAME}:latest"
    
    # 推送 latest 标签
    echo "🚀 推送 latest 标签..."
    docker push "${DOCKER_USERNAME}/${IMAGE_NAME}:latest"
    
    echo "✅ 成功更新 latest 标签指向 ${version}"
    echo "   镜像: ${DOCKER_USERNAME}/${IMAGE_NAME}:latest"
    echo "   现在指向: ${DOCKER_USERNAME}/${IMAGE_NAME}:${version}"
}

# 如果命令是 update-latest，执行更新操作
if [ "$COMMAND" = "update-latest" ]; then
    update_latest_tag "$TARGET_VERSION"
    exit 0
fi

# 创建并切换到新的 builder 实例
echo "🚀 设置 Docker Buildx 构建器..."
if ! docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
    echo "  创建新的构建器: $BUILDER_NAME"
    docker buildx create --name "$BUILDER_NAME" --use
else
    echo "  使用现有构建器: $BUILDER_NAME"
    docker buildx use "$BUILDER_NAME"
fi

# 启动构建器
echo "🔧 启动构建器..."
docker buildx inspect --bootstrap

# 准备输出目录
mkdir -p "$OUTPUT_DIR"

# 构建参数
BUILD_ARGS=(
    --platform "$PLATFORMS"
)

# 如果是仅构建模式，确保镜像保存在本地
if [ "$BUILD_ONLY" = true ]; then
    echo "🔨 仅构建模式: 镜像将保存到本地 Docker 镜像"
    # 添加 --load 参数将镜像加载到本地 Docker
    BUILD_ARGS+=(--load)
    # 添加标签
    BUILD_ARGS+=(-t "$FULL_IMAGE_NAME")
    # 为每个平台单独构建并加载到本地
    IFS=',' read -ra PLATFORM_ARRAY <<< "$PLATFORMS"
    for platform in "${PLATFORM_ARRAY[@]}"; do
        platform_sanitized=${platform//\//-}
        echo "  正在构建平台: $platform"
        docker buildx build \
            --platform "$platform" \
            -t "${FULL_IMAGE_NAME}-${platform_sanitized}" \
            --load \
            .
    done
    echo "✅ 所有平台构建完成，镜像已加载到本地 Docker"
    echo "   使用 'docker images | grep ${IMAGE_NAME}' 查看镜像"
    exit 0
else
    # 推送模式，添加标签
    BUILD_ARGS+=(-t "$FULL_IMAGE_NAME")
fi

# 如果启用了推送，则添加 --push 参数
if [ "$PUSH_TO_HUB" = true ] && [ "$BUILD_ONLY" = false ]; then
    echo "🔑 登录到 Docker Hub..."
    docker login
    
    # 添加推送参数
    BUILD_ARGS+=(--push)
    echo "🚀 构建并推送多平台镜像: $FULL_IMAGE_NAME"
    echo "   平台: $PLATFORMS"
elif [ "$BUILD_ONLY" = true ]; then
    echo "🔨 仅构建模式: 镜像将保存到 ${OUTPUT_DIR}/"
    echo "   平台: $PLATFORMS"
else
    echo "🚀 构建多平台镜像 (本地): $FULL_IMAGE_NAME"
    echo "   平台: $PLATFORMS"
    echo "   注意: 使用 --push 参数推送到 Docker Hub 或 --build-only 仅构建"
fi

# 添加构建上下文
BUILD_ARGS+=(.)

# 执行构建命令
echo "🛠️  开始构建..."
docker buildx build "${BUILD_ARGS[@]}"

# 显示构建结果
if [ $? -eq 0 ]; then
    echo -e "\n✅ 构建完成!"
    
    if [ "$PUSH_TO_HUB" = true ]; then
        echo "   镜像已推送到 Docker Hub: $FULL_IMAGE_NAME"
        echo "   使用以下命令检查镜像信息:"
        echo "   docker buildx imagetools inspect $FULL_IMAGE_NAME"
    else
        echo "   镜像仅存在于本地构建缓存中"
        echo "   使用 --push 参数推送到 Docker Hub"
    fi
else
    echo -e "\n❌ 构建失败!"
    exit 1
fi
