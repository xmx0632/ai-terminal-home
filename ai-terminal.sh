#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 容器名称
CONTAINER_NAME="ai-terminal-home"

# 显示帮助信息
show_help() {
    echo -e "${YELLOW}AI Terminal Home 管理脚本${NC}"
    echo "用法: $0 [命令]"
    echo ""
    echo "可用命令:"
    echo "  build [version] [force] 构建 Docker 镜像（可指定版本号和是否强制重建）"
    echo "  start [version]   启动容器（如果不存在则构建，支持指定版本号）"
    echo "  stop              停止容器"
    echo "  restart           重启容器"
    echo "  status            查看容器状态"
    echo "  logs              查看容器日志"
    echo "  shell             进入容器 shell"
    echo "  versions          显示已安装工具的版本信息"
    echo "  upgrade cc        升级容器内的 claudecode"
    echo "  upgrade gcli      升级容器内的 gemini cli"
    echo "  help              显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 build"
    echo "  $0 start"
    echo "  $0 stop"
    echo "  $0 logs"
    echo "  $0 upgrade cc"
    echo "  $0 upgrade gcli"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查 Docker 是否安装
check_docker() {
    if ! command_exists docker; then
        echo -e "${RED}错误: Docker 未安装${NC}"
        exit 1
    fi
    
    if ! command_exists docker-compose; then
        echo -e "${RED}错误: Docker Compose 未安装${NC}"
        exit 1
    fi
}

# 构建镜像
build_image() {
    local version=${1:-latest}
    local force_rebuild=${2:-false}
    
    if [ "$version" != "latest" ]; then
        echo -e "${GREEN}使用版本号: $version${NC}"
    fi
    
    # 如果强制重建，先删除现有镜像
    if [ "$force_rebuild" = true ]; then
        echo -e "${YELLOW}正在删除现有镜像...${NC}"
        docker rmi -f $(docker images -q ai-terminal-home-ai-terminal-home xmx0632/ai-terminal-home 2>/dev/null) 2>/dev/null || true
        echo -e "${YELLOW}正在清理未使用的镜像...${NC}"
        docker image prune -f
    fi
    
    echo -e "${YELLOW}正在构建 Docker 镜像...${NC}"
    
    # 使用 docker-compose build 构建镜像，指定 profile 为 build
    local build_cmd="docker-compose --profile build build"
    if [ "$force_rebuild" = true ]; then
        build_cmd="$build_cmd --no-cache"
    fi
    
    if $build_cmd --build-arg VERSION="$version" --build-arg CACHE_BUSTER="$(date +%s)"; then
        # 获取新构建的镜像ID
        local image_id=$(docker images -q ai-terminal-home-ai-terminal-home:latest 2>/dev/null)
        
        if [ -n "$image_id" ]; then
            # 标记镜像
            local repo="xmx0632/ai-terminal-home"
            
            # 如果指定了版本号，则标记版本
            if [ "$version" != "latest" ]; then
                echo -e "${GREEN}正在标记镜像版本: $version${NC}"
                docker tag $image_id $repo:$version
            fi
            
            # 始终标记为 latest
            docker tag $image_id $repo:latest
            
            # 显示镜像信息
            echo -e "${GREEN}镜像构建并标记成功!${NC}\n${YELLOW}镜像信息:${NC}"
            # docker images | head -n 1
            docker images | grep -E 'REPOSITORY|ai-terminal-home'
        else
            echo -e "${YELLOW}警告: 无法获取新构建的镜像ID${NC}"
            docker images | head -n 1
            docker images | grep ai-terminal-home || echo "未找到相关镜像"
        fi
    else
        echo -e "${RED}镜像构建失败!${NC}"
        exit 1
    fi
}

# 启动容器
start_container() {
    local version=${1:-latest}
    
    # 检查版本号是否有效
    if [ "$version" != "latest" ]; then
        echo -e "${GREEN}尝试启动版本: $version${NC}"
    fi
    
    # 首先检查本地是否存在指定版本的镜像
    if docker images xmx0632/ai-terminal-home:$version | grep -q $version; then
        echo -e "${GREEN}使用本地镜像版本: $version${NC}"
    else
        # 本地不存在指定版本，尝试拉取
        echo -e "${YELLOW}本地不存在版本 ${version}，正在尝试拉取镜像...${NC}"
        if ! docker pull xmx0632/ai-terminal-home:$version 2>/dev/null; then
            if [ "$version" != "latest" ]; then
                echo -e "${YELLOW}版本 $version 不存在，尝试使用 latest 版本${NC}"
            fi
            version="latest"
            # 检查本地latest版本是否存在
            if ! docker images xmx0632/ai-terminal-home:latest | grep -q latest; then
                # 本地不存在latest版本，尝试拉取
                if ! docker pull xmx0632/ai-terminal-home:latest; then
                    echo -e "${RED}错误: 无法拉取 latest 版本的镜像${NC}"
                    exit 1
                fi
            else
                echo -e "${GREEN}使用本地 latest 镜像${NC}"
            fi
        fi
    fi
    
    # 停止并删除现有容器
    if [ -n "$(docker ps -a -q -f name=^${CONTAINER_NAME}$)" ]; then
        stop_container
    fi
    
    # 设置环境变量并启动容器
    echo -e "${YELLOW}正在启动容器...${NC}"
    if VERSION="$version" docker-compose --profile pull up -d; then
        echo -e "${GREEN}容器启动成功!${NC}"
        echo -e "使用 'docker exec -it $CONTAINER_NAME bash' 进入容器"
    else
        echo -e "${RED}容器启动失败!${NC}"
        exit 1
    fi
}

# 停止容器
stop_container() {
    echo -e "${YELLOW}正在停止容器...${NC}"
    
    # 先停止容器
    if docker stop ${CONTAINER_NAME} >/dev/null; then
        echo -e "${GREEN}容器已停止!${NC}"
    else
        echo -e "${YELLOW}停止容器时出错或容器未运行${NC}"
    fi
    
    # 删除容器
    if docker rm ${CONTAINER_NAME} >/dev/null 2>&1; then
        echo -e "${GREEN}容器已删除!${NC}"
    else
        echo -e "${YELLOW}删除容器时出错或容器不存在${NC}"
    fi
}

# 重启容器
restart_container() {
    echo -e "${YELLOW}正在重启容器...${NC}"
    docker-compose restart
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}容器已重启!${NC}"
    else
        echo -e "${RED}重启容器时出错!${NC}"
        exit 1
    fi
}

# 查看容器状态
container_status() {
    echo -e "${YELLOW}容器状态:${NC}"
    docker ps -a | grep ${CONTAINER_NAME}
    
    echo -e "\n${YELLOW}日志最后 10 行:${NC}"
    docker logs --tail=10 ${CONTAINER_NAME}
}

# 查看容器日志
show_logs() {
    echo -e "${YELLOW}正在显示容器日志 (Ctrl+C 退出)...${NC}"
    docker-compose logs -f
}

# 进入容器 shell
enter_shell() {
    # 检查容器是否在运行
    if [ "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
        echo -e "${YELLOW}正在进入容器 shell...${NC}"
        echo -e "${GREEN}使用 'exit' 退出容器${NC}"
        # 使用 -i 保持 STDIN 打开，-t 分配一个伪终端
        docker exec -it ${CONTAINER_NAME} /bin/bash || \
        docker exec -it ${CONTAINER_NAME} /bin/sh || \
        (echo -e "${RED}无法进入容器 shell，请尝试手动执行: docker exec -it ${CONTAINER_NAME} /bin/bash${NC}" && exit 1)
    else
        echo -e "${RED}错误: 容器未运行，请先启动容器${NC}"
        exit 1
    fi
}

# 显示已安装工具的版本
show_versions() {
    if [ "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
        echo -e "${YELLOW}已安装工具版本:${NC}"
        echo "----------------------------"
        echo -n "Node.js: " && docker exec ${CONTAINER_NAME} node --version 2>/dev/null || echo "未安装"
        echo -n "npm:     " && docker exec ${CONTAINER_NAME} npm --version 2>/dev/null || echo "未安装"
        echo -n "Yarn:    " && docker exec ${CONTAINER_NAME} yarn --version 2>/dev/null || echo "未安装"
        echo -n "Claude:  " && (docker exec ${CONTAINER_NAME} claude --version 2>/dev/null || echo "未安装")
        echo -n "Gemini:  " && (docker exec ${CONTAINER_NAME} gemini --version 2>/dev/null || echo "未安装")
    else
        echo -e "${RED}错误: 容器未运行，请先启动容器${NC}"
        exit 1
    fi
}

# 升级 claudecode
upgrade_cc() {
    if [ "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
        echo -e "${YELLOW}正在升级 claudecode...${NC}"
        docker exec ${CONTAINER_NAME} npm install -g @anthropic-ai/claude-code || {
            echo -e "${RED}错误: 升级 claudecode 失败${NC}"
            return 1
        }
        echo -e "${GREEN}claudecode 升级成功!${NC}"
        echo -n "当前版本: "
        docker exec ${CONTAINER_NAME} claude --version 2>/dev/null || echo "未知"
    else
        echo -e "${RED}错误: 容器未运行，请先启动容器${NC}"
        exit 1
    fi
}

# 升级 gemini cli
upgrade_gcli() {
    if [ "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
        echo -e "${YELLOW}正在升级 gemini cli...${NC}"
        docker exec ${CONTAINER_NAME} npm install -g @google/gemini-cli || {
            echo -e "${RED}错误: 升级 gemini cli 失败${NC}"
            return 1
        }
        echo -e "${GREEN}gemini cli 升级成功!${NC}"
        echo -n "当前版本: "
        docker exec ${CONTAINER_NAME} gemini --version 2>/dev/null || echo "未知"
    else
        echo -e "${RED}错误: 容器未运行，请先启动容器${NC}"
        exit 1
    fi
}

# 主函数
main() {
    # 检查 Docker 是否安装
    check_docker

    # 解析命令行参数
    case "$1" in
        build)
            build_image "$2" "${3:-false}"  # 第二个参数为版本号，第三个参数为是否强制重建
            ;;
        start)
            start_container "$2"
            ;;
        stop)
            stop_container
            ;;
        restart)
            restart_container
            ;;
        status)
            container_status
            ;;
        logs)
            show_logs
            ;;
        shell)
            enter_shell
            ;;
        versions)
            show_versions
            ;;
        upgrade)
            case "$2" in
                cc)
                    upgrade_cc
                    ;;
                gcli)
                    upgrade_gcli
                    ;;
                *)
                    echo -e "${RED}错误: 未知的升级目标 '$2'${NC}"
                    echo "可用目标: cc, gcli"
                    exit 1
                    ;;
            esac
            ;;
        help|--help|-h|*)
            show_help
            ;;
    esac
}

# 执行主函数
main "$@"
