# AI Terminal Home

> A Docker-based AI development sandbox environment with integrated Claude Code AI and Gemini CLI toolchain

## Features

- 🐳 Lightweight Docker container based on Ubuntu 22.04
- 🤖 Pre-installed Claude Code AI and Gemini CLI
- 🛡️ Secure sandbox environment that protects the host system
- 💾 Data persistence through volume mounting
- 🚀 Ready-to-use development environment
- 🛠️ Comprehensive management script for daily operations
- 🔄 Proxy configuration support for network access
- 📦 Pre-built Docker images available for quick deployment

## Quick Start

### Method 1: Using Pre-built Images (Recommended)

1. Pull and run the latest image from Docker Hub:
   ```bash
   # Pull and run the latest version
   VERSION=0.0.1 docker-compose -f docker-compose.pull.yaml up -d
   
   # Or specify a version
   VERSION=0.0.1 docker-compose -f docker-compose.pull.yaml up -d
   ```

2. Access the container:
   ```bash
   docker exec -it ai-terminal-home bash
   ```

### Method 2: Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/ai-terminal-home.git
   cd ai-terminal-home
   ```

2. Build and start the container:
   ```bash
   # Build and start
   docker-compose up -d --build
   
   # View logs
   docker-compose logs -f
   ```

3. Access the container:
   ```bash
   docker exec -it ai-terminal-home bash
   ```

## Environment Variables

Configure the following environment variables in the `.env` file:

```ini
# API Keys
ANTHROPIC_AUTH_TOKEN=your_api_key_sk
GEMINI_API_KEY=your_gemini_api_key

# Proxy Settings
https_proxy=http://127.0.0.1:7890
http_proxy=http://127.0.0.1:7890
all_proxy=socks5://127.0.0.1:7890
```

## Management Commands

### Start/Stop Containers

```bash
# Start using local build (default)
./ai-terminal.sh start

# Start using pre-built image
./ai-terminal.sh start --pull

# Stop
./ai-terminal.sh stop

# Restart
./ai-terminal.sh restart
```

### View Logs

```bash
# View logs
./ai-terminal.sh logs

# View logs for pre-built image
./ai-terminal.sh logs --pull

# Follow logs in real-time
./ai-terminal.sh logs -f
```

### Other Commands

```bash
# Check container status
./ai-terminal.sh status

# Update container
./ai-terminal.sh update          # Update local build
./ai-terminal.sh update --pull   # Update pre-built image

# Show installed tool versions
./ai-terminal.sh versions

# Show help
./ai-terminal.sh help
```

## Using tmux for Session Management

### Viewing tmux Sessions

Inside the container, you can use tmux to manage multiple terminal sessions. To view current tmux sessions, use:

```bash
tmux ls
```

![View tmux sessions](./images/image-tmux-ls.png)

### Running Gemini and Claude Code

You can run both Gemini and Claude Code simultaneously in tmux:

1. Start a new tmux session:
   ```bash
   tmux new -s ai
   ```

2. Split the window:
   - Horizontal split: `Ctrl+b "`
   - Vertical split: `Ctrl+b %`

3. Run in different panes:
   - Gemini: `gemini`
   - Claude Code: `claude`

![Gemini and Claude Code running together](./images/image-gemini-cc.png)

### Common tmux Commands

- Create new window: `Ctrl+b c`
- Switch windows: `Ctrl+b [window number]`
- Detach session: `Ctrl+b d`
- Reattach session: `tmux attach -t ai`
- List sessions: `tmux ls`
- Kill session: `tmux kill-session -t ai`

## Building and Publishing

### Building a New Version

1. Update the version number:
   ```bash
   # Update VERSION in docker-compose.pull.yaml
   VERSION=0.0.2
   ```

2. Build and push the image:
   ```bash
   # Build the image (for local build only)
   ./ai-terminal.sh build
   
   # Push the image to Docker Hub
   ./push-image.sh -u your_dockerhub_username -v 0.0.2
   
   # After pushing, you can pull and run the new version with:
   # VERSION=0.0.2 ./ai-terminal.sh start --pull
   ```

## FAQ

### How to update to the latest version?

```bash
# Stop and remove the old container
docker-compose -f docker-compose.pull.yaml down

# Pull and start the new version
VERSION=latest docker-compose -f docker-compose.pull.yaml up -d
```

### How to view container logs?

```bash
docker-compose -f docker-compose.pull.yaml logs -f
```

## License

MIT License
