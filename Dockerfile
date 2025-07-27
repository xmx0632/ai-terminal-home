FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai \
    NODE_VERSION=20.x \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8

# 设置时区
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
    locales \
    fonts-wqy-microhei \
    fonts-wqy-zenhei \
    ttf-wqy-microhei \
    ttf-wqy-zenhei \
    xfonts-wqy \
    && rm -rf /var/lib/apt/lists/*

# 生成中文语言环境
RUN sed -i '/zh_CN.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

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

# 设置 tmux 配置
RUN echo 'set -g default-command "LANG=zh_CN.UTF-8 /bin/bash --login"' > /root/.tmux.conf && \
    echo 'set -g default-terminal "screen-256color"' >> /root/.tmux.conf && \
    echo 'set -g status-utf8 on' >> /root/.tmux.conf && \
    echo 'set -g mouse on' >> /root/.tmux.conf

# 设置入口脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 设置默认工作目录
WORKDIR /data

# 设置入口点
ENTRYPOINT ["/entrypoint.sh"]

# 默认命令
CMD ["tmux"]