FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai \
    NODE_VERSION=20.x

# 设置时区
ENV TZ=Asia/Shanghai
RUN ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo $TZ > /etc/timezone

# 备份原始源列表
RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak

# 更新软件包索引并安装必要工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# 安装 NodeSource
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION%%.*}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list

# 定义基础工具列表
ENV BASE_PACKAGES="curl git tmux vim wget tzdata"

# 安装基础工具和 Node.js
RUN apt-get update && \
    # 检查并安装缺失的基础工具
    for pkg in $BASE_PACKAGES; do \
        if ! command -v $pkg > /dev/null 2>&1; then \
            apt-get install -y --no-install-recommends $pkg || true; \
        fi \
    done && \
    # 安装 Node.js
    apt-get install -y --no-install-recommends nodejs && \
    # 清理缓存
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 配置 npm 和安装 yarn
RUN npm install -g npm@latest && \
    npm config set registry https://registry.npmmirror.com/ && \
    npm install -g yarn

# 验证 Node.js 和 npm 版本
RUN node --version && npm --version && yarn --version

# 设置工作目录
WORKDIR /app

# 安装 Claude Code AI (官方 npm 包)
RUN npm install -g @anthropic-ai/claude-code

# 安装 Gemini CLI (官方 npm 包)
RUN npm install -g @google/gemini-cli

# 设置数据目录
RUN mkdir -p /data

# 设置入口脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 设置默认工作目录
WORKDIR /data

# 设置入口点
ENTRYPOINT ["/entrypoint.sh"]

# 默认命令
CMD ["tmux"]