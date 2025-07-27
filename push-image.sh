#!/bin/bash

# push image to dockerhub
# ./push-image.sh -u xmx0632 -v 0.0.1  -i ai-terminal-home


# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 默认值
DEFAULT_DOCKER_USERNAME="xmx0632"
DEFAULT_IMAGE_NAME="ai-terminal-home"
DEFAULT_VERSION="0.0.1"

# 显示帮助信息
show_help() {
    echo -e "${YELLOW}使用方法: $0 [选项]${NC}"
    echo ""
    echo "选项:"
    echo "  -u, --username    Docker Hub 用户名 (默认: ${DEFAULT_DOCKER_USERNAME})"
    echo "  -i, --image       镜像名称 (默认: ${DEFAULT_IMAGE_NAME})"
    echo "  -v, --version     版本号 (默认: ${DEFAULT_VERSION})"
    echo "  -h, --help        显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -u myusername -i myimage -v 1.0.0"
    echo "  $0 --username myusername --version 2.0.0"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -u|--username)
        DOCKER_USERNAME="$2"
        shift # 移出参数名
        shift # 移出参数值
        ;;
        -i|--image)
        IMAGE_NAME="$2"
        shift
        shift
        ;;
        -v|--version)
        VERSION="$2"
        shift
        shift
        ;;
        -h|--help)
        show_help
        exit 0
        ;;
        *)
        echo -e "${RED}未知选项: $1${NC}"
        show_help
        exit 1
        ;;
    esac
done

# 设置默认值
DOCKER_USERNAME=${DOCKER_USERNAME:-$DEFAULT_DOCKER_USERNAME}
IMAGE_NAME=${IMAGE_NAME:-$DEFAULT_IMAGE_NAME}
VERSION=${VERSION:-$DEFAULT_VERSION}

# 检查是否已登录 Docker Hub
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}错误: 请先登录 Docker Hub${NC}"
    echo "请运行: docker login"
    exit 1
fi

# 获取当前镜像 ID
IMAGE_ID=$(docker images -q ${DEFAULT_IMAGE_NAME}-${DEFAULT_IMAGE_NAME} 2> /dev/null)

if [ -z "$IMAGE_ID" ]; then
    echo -e "${YELLOW}警告: 未找到本地镜像 ${DEFAULT_IMAGE_NAME}-${DEFAULT_IMAGE_NAME}${NC}"
    echo -e "${YELLOW}正在尝试构建镜像...${NC}"
    if ! ./ai-terminal.sh build; then
        echo -e "${RED}错误: 构建镜像失败${NC}"
        exit 1
    fi
    IMAGE_ID=$(docker images -q ${DEFAULT_IMAGE_NAME}-${DEFAULT_IMAGE_NAME} 2> /dev/null)
    if [ -z "$IMAGE_ID" ]; then
        echo -e "${RED}错误: 构建后仍未找到镜像${NC}"
        exit 1
    fi
fi

# 标记镜像
TARGET_IMAGE="${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION}"
echo -e "${YELLOW}正在标记镜像...${NC}"
echo "源镜像: ${DEFAULT_IMAGE_NAME}-${DEFAULT_IMAGE_NAME}"
echo "目标镜像: ${TARGET_IMAGE}"

docker tag ${DEFAULT_IMAGE_NAME}-${DEFAULT_IMAGE_NAME} ${TARGET_IMAGE}

if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 标记镜像失败${NC}"
    exit 1
fi

# 推送镜像到 Docker Hub
echo -e "${YELLOW}正在推送镜像到 Docker Hub...${NC}"
docker push ${TARGET_IMAGE}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}成功推送镜像: ${TARGET_IMAGE}${NC}"
    
    # 同时标记为 latest
    echo -e "${YELLOW}同时标记为 latest 版本...${NC}"
    docker tag ${TARGET_IMAGE} ${DOCKER_USERNAME}/${IMAGE_NAME}:latest
    docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:latest
    
    echo -e "${GREEN}镜像已成功推送到 Docker Hub:${NC}"
    echo "- ${TARGET_IMAGE}"
    echo "- ${DOCKER_USERNAME}/${IMAGE_NAME}:latest"
else
    echo -e "${RED}错误: 推送镜像失败${NC}"
    exit 1
fi
