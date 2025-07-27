#!/bin/bash

# 设置环境变量
export ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL}
export ANTHROPIC_AUTH_TOKEN=${ANTHROPIC_AUTH_TOKEN}
export GEMINI_API_KEY=${GEMINI_API_KEY}

# 显示欢迎信息
echo "=================================================="
echo "AI Terminal Home 环境已启动"
echo "=================================================="

# 显示 Node.js 环境信息
echo "Node.js 版本: $(node --version)"
echo "npm 版本: $(npm --version)"
echo "yarn 版本: $(yarn --version)"

echo ""
echo "已安装工具:"
if command -v claude &> /dev/null; then
  echo "- Claude Code AI 已安装 (通过 npm 全局安装)"
  echo "  运行命令: claude"
fi

if command -v gemini &> /dev/null; then
  echo "- Gemini CLI 已安装 (通过 npm 全局安装)"
  echo "  运行命令: gemini"
fi

echo ""
echo "数据目录已挂载: /data"
echo ""
echo "使用说明:"
echo "1. 使用 tmux 创建新会话: tmux new -s my_session"
echo "2. 在 tmux 中运行 Claude Code AI: claude"
echo "3. 在 tmux 中运行 Gemini CLI: gemini"
echo "4. 分离会话: Ctrl+b d"
echo "5. 重新连接会话: tmux a -t my_session"
echo ""
echo "=================================================="

# 执行传入的命令
exec "$@"
