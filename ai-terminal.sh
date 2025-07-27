#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 容器名称
CONTAINER_NAME="ai-terminal-home"
# 默认使用构建配置
COMPOSE_FILE="docker-compose.yaml"

# 显示帮助信息
show_help() {
    echo -e "${YELLOW}AI Terminal Home 管理脚本${NC}"
    echo "用法: $0 [命令] [选项]"
    echo ""
    echo "可用命令:"
    echo "  build             构建 Docker 镜像"
    echo "  start             启动容器（如果不存在则构建）"
    echo "  stop              停止容器"
    echo "  restart           重启容器"
    echo "  status            查看容器状态"
    echo "  logs              查看容器日志"
    echo "  update            更新代码并重建容器"
    echo "  shell             进入容器 shell"
    echo "  versions          显示已安装工具的版本信息"
    echo "  help              显示此帮助信息"
    echo ""
    echo "选项:"
    echo "  --pull            使用预构建的 Docker 镜像（从 Docker Hub 拉取）"
    echo ""
    echo "示例:"
    echo "  $0 build"
    echo "  $0 start"
    echo "  $0 start --pull   使用预构建镜像启动"
    echo "  $0 stop"
    echo "  $0 logs"
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
    local compose_file=$1
    echo -e "${GREEN}正在构建 Docker 镜像...${NC}"
    docker-compose -f "$compose_file" build
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}镜像构建成功!${NC}"
    else
        echo -e "${RED}镜像构建失败!${NC}"
        exit 1
    fi
}

# 启动容器
start_container() {
    local compose_file=$1
    # 检查容器是否已存在
    if [ "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then
        # 容器存在，检查是否在运行
        if [ "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
            echo -e "${YELLOW}容器已经在运行中!${NC}"
            return 0
        else
            echo -e "${YELLOW}启动已存在的容器...${NC}"
            docker start ${CONTAINER_NAME}
        fi
    else
        echo -e "${GREEN}创建并启动新容器...${NC}"
        docker-compose -f "$compose_file" up -d
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}容器启动成功!${NC}"
        echo -e "${YELLOW}使用 'docker exec -it ${CONTAINER_NAME} bash' 进入容器${NC}"
    else
        echo -e "${RED}容器启动失败!${NC}"
        exit 1
    fi
}

# 停止容器
stop_container() {
    local compose_file=$1
    echo -e "${YELLOW}正在停止容器...${NC}"
    docker-compose -f "$compose_file" down
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}容器已停止!${NC}"
    else
        echo -e "${RED}停止容器时出错!${NC}"
        exit 1
    fi
}

# 重启容器
restart_container() {
    local compose_file=$1
    echo -e "${YELLOW}正在重启容器...${NC}"
    docker-compose -f "$compose_file" restart
    
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
    local compose_file=$1
    echo -e "${YELLOW}正在显示容器日志 (Ctrl+C 退出)...${NC}"
    docker-compose -f "$compose_file" logs -f
}

# 更新容器
update_container() {
    local compose_file=$1
    echo -e "${YELLOW}正在更新容器...${NC}"
    
    # 如果是拉取模式，直接重新拉取镜像
    if [ "$compose_file" = "docker-compose.pull.yaml" ]; then
        echo -e "${GREEN}拉取最新镜像...${NC}"
        docker-compose -f "$compose_file" pull
    else
        # 否则从源码构建
        echo -e "${GREEN}拉取最新代码...${NC}"
        git pull
        
        # 重新构建镜像
        build_image "$compose_file"
    fi
    
    # 停止并删除旧容器
    echo -e "${GREEN}重新创建容器...${NC}"
    docker-compose -f "$compose_file" up -d --force-recreate
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}容器更新成功!${NC}"
    else
        echo -e "${RED}容器更新失败!${NC}"
        exit 1
    fi
}

# 进入容器 shell
enter_shell() {
    echo -e "${YELLOW}正在进入容器 shell...${NC}"
    echo -e "${GREEN}使用 'exit' 退出容器${NC}"
    docker exec -it ${CONTAINER_NAME} bash
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

# 主函数
main() {
    # 检查 Docker 是否安装
    check_docker
    
    # 解析选项
    local pull_mode=false
    local args=()
    
    # 处理选项参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --pull)
                pull_mode=true
                shift
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    
    # 设置 compose 文件
    local compose_file="docker-compose.yaml"
    if [ "$pull_mode" = true ]; then
        compose_file="docker-compose.pull.yaml"
        echo -e "${YELLOW}使用预构建镜像模式${NC}"
    fi
    
    # 解析命令
    case "${args[0]}" in
        build)
            if [ "$pull_mode" = true ]; then
                echo -e "${YELLOW}拉取模式下无需构建，使用 'start --pull' 启动容器${NC}"
                exit 0
            fi
            build_image "$compose_file"
            ;;
        start)
            start_container "$compose_file"
            ;;
        stop)
            stop_container "$compose_file"
            ;;
        restart)
            restart_container "$compose_file"
            ;;
        status)
            container_status
            ;;
        logs)
            show_logs "$compose_file"
            ;;
        update)
            update_container "$compose_file"
            ;;
        shell)
            enter_shell
            ;;
        versions)
            show_versions
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}未知命令: ${args[0]}${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
