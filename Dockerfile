FROM node:22-bookworm-slim

# Keep base image non-interactive and set production defaults
ENV DEBIAN_FRONTEND=noninteractive \
    NODE_ENV=production

# Install system dependencies, GitHub CLI, Docker CLI, build tools, and utilities
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       ca-certificates curl git bash openssh-client gnupg python3 python3-pip python3-venv make g++ unzip \
       tmux nano ripgrep jq tree bat fd-find man tldr \
       libnss3 libnspr4 libdbus-1-3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 libcairo2 libasound2 libatspi2.0-0 \
       libx11-xcb1 libxcursor1 libgtk-3-0 libgdk-pixbuf2.0-0 \
       # WebKit browser dependencies
       libgstreamer1.0-0 libgstreamer-plugins-base1.0-0 gstreamer1.0-plugins-good \
       libgstreamer-gl1.0-0 libgstreamer-plugins-bad1.0-0 \
       libgtk-4-1 libgraphene-1.0-0 libxslt1.1 libxml2 \
       libevent-2.1-7 libopus0 \
       libflite1 \
       libavif15 libharfbuzz-icu0 \
       libsecret-1-0 libenchant-2-2 libhyphen0 \
       libmanette-0.2-0 \
       libx264-dev libgles2 libwoff1 \
       imagemagick libvips librsvg2-bin pngquant libwebp-dev \
  && mkdir -p -m 755 /etc/apt/keyrings \
  && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
  && curl -fsSL https://download.docker.com/linux/debian/gpg \
       | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" \
       > /etc/apt/sources.list.d/docker.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
       gh docker-ce-cli docker-compose-plugin \
  && rm -rf /var/lib/apt/lists/*

# Install pipx for Python package isolation
RUN pip3 install --break-system-packages pipx && pipx ensurepath

# Create cache directories for runtime-installed tools (accessible by non-root user)
RUN mkdir -p /home/node/.npm \
               /home/node/.cache/ms-playwright \
               /home/node/.local/share/pipx \
               /home/node/.local/bin \
               /home/node/npm-modules \
               /home/node/.cursor \
    && chmod -R 755 /home/node/.npm \
               /home/node/.cache \
               /home/node/.local \
               /home/node/npm-modules \
               /home/node/.cursor

# Install SVGO for SVG optimization
RUN npm install -g svgo

# Install OpenAI Codex CLI globally and cache the binary
RUN npm install -g @openai/codex@latest \
  && codex --version >/tmp/codex-version

# Install vibe-kanban at build time (not runtime)
# This ensures the Docker image digest changes when a new version is released,
# which enables UnRAID's "Update Available" detection
ARG VIBE_VERSION=latest
RUN npm install -g vibe-kanban@${VIBE_VERSION}

# Copy startup script for runtime tool installation
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# Dedicated workspace for mounted repositories
WORKDIR /work

EXPOSE 8080

# Default git identity (override via docker-compose env if needed)
ENV GIT_AUTHOR_NAME="Your Name" \
    GIT_AUTHOR_EMAIL="you@example.com" \
    GIT_COMMITTER_NAME="Your Name" \
    GIT_COMMITTER_EMAIL="you@example.com"

# Launch Vibe Kanban via startup script (handles runtime tool installation)
CMD ["/usr/local/bin/startup.sh", "bash", "-lc", "vibe-kanban"]
