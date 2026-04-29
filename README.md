# Vibe Kanban in Docker

[![Node.js](https://img.shields.io/badge/Node.js-22.x-339933?logo=node.js&logoColor=white)](https://nodejs.org/)
[![Docker Compose](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![GitHub CLI](https://img.shields.io/badge/GitHub-CLI-181717?logo=github)](https://cli.github.com/)
[![OpenAI Codex](https://img.shields.io/badge/OpenAI-Codex-412991?logo=openai&logoColor=white)](https://www.vibekanban.com/docs/agents/openai-codex)

Containerized developer environment for [Vibe Kanban](https://github.com/BloopAI/vibe-kanban) with GitHub CLI, Docker CLI, and OpenAI Codex baked in. Designed for WSL2 + Docker Desktop, but works on any host that can mount the Docker socket and your credentials.

---

## ✨ Highlights

- **One-command spin-up** via Docker Compose with reproducible dependencies.
- **Codex-ready**: `@openai/codex` installed globally, config persisted through `~/.codex`.
- **GitHub workflow**: GitHub CLI and optional token/env wiring already configured.
- **Docker-in-Docker tooling**: Container includes `docker` + compose plugin and mounts the host socket.
- **Workspace mounts**: Your repo, SSH keys, git config, and CLI auth all ride along.

---

## 🚀 Quick Start

```bash
# 1. Pick up optional env overrides
cp examples/.env.example .env  # then edit as needed
echo "LOCAL_UID=$(id -u)" >> .env
echo "LOCAL_GID=$(id -g)" >> .env

# 2. Prepare persistent volumes
mkdir -p data/vibe data/work

# 3. Build and start the stack
docker compose build
docker compose up -d

# 4. Visit the app
open http://localhost:8085   # or use your browser
```

The service runs as `vibe` inside the Compose file and exposes port `8085` by default. Adjust in `docker-compose.yml` if you prefer another port.

---

### Local Docker overlays

Need extra packages or different dev settings without touching git-tracked files? Copy the provided templates and opt in locally:

```bash
cp examples/Dockerfile.local.example Dockerfile.local
cp examples/docker-compose.local.yml.example docker-compose.local.yml
```

Build the base image once (`docker build -t vibe-kanban:base -f Dockerfile .`), then rebuild with your overrides (`docker compose -f docker-compose.yml -f docker-compose.local.yml up`). Both `.local` files are ignored by git.

---

## 🔑 Integrations & Credentials

### Coding Agents

This image includes **OpenAI Codex** by default. Additional coding agents can be installed at **runtime** via environment variables.

Supports both space-separated (`claude gemini`) and comma-separated (`claude,gemini`) values.

#### Available Agents

| Agent | Package | Description |
|-------|---------|-------------|
| Codex | `@openai/codex` | OpenAI Codex (default) |
| `claude` | `@anthropic-ai/claude-code` | Anthropic Claude Code |
| `gemini` | `@google/gemini-cli` | Google Gemini CLI |
| `copilot` | `@githubnext/copilot-cli` | GitHub Copilot |
| `amp` | `amp-code` | Amp Code |
| `cursor` | `@cursor/cli` | Cursor Agent CLI |
| `opencode` | `@opencode-ai/cli` | SST OpenCode |
| `droid` | `droid-cli` | Factory Droid |
| `clauderouter` | `claude-code-router` | Claude Code Router |
| `qwen` | `qwen-code` | Qwen Code |

#### Docker Run

```bash
docker run -e "RUNTIME_AGENTS=claude gemini" ghcr.io/rorar/vibe-kanban-docker:latest
```

#### Docker Compose

```yaml
services:
  vibe:
    image: ghcr.io/rorar/vibe-kanban-docker:latest
    environment:
      - RUNTIME_AGENTS=claude gemini
```

#### UnRAID Template

Use the template inputs for `RUNTIME_AGENTS` field.

Each agent requires its own authentication. After building, authenticate on the host and the credentials will be mounted into the container.

### Playwright E2E Testing

Playwright is available for E2E testing. Install browsers at **runtime** (supports space or comma-separated values):

```bash
docker run -e "RUNTIME_PLAYWRIGHT_BROWSERS=chromium firefox" ghcr.io/rorar/vibe-kanban-docker:latest
# or
docker run -e "RUNTIME_PLAYWRIGHT_BROWSERS=chromium,firefox,webkit" ghcr.io/rorar/vibe-kanban-docker:latest
```

**Run tests:**
```bash
npx playwright test              # Run all configured browsers
npx playwright test --project=chromium  # Single browser
npx playwright show-report       # View HTML report
```

### Unit & Integration Testing

Install testing frameworks at **runtime** (supports space or comma-separated values):

```bash
docker run -e "RUNTIME_TESTING_TOOLS=vitest jest msw" ghcr.io/rorar/vibe-kanban-docker:latest
# or
docker run -e "RUNTIME_TESTING_TOOLS=vitest,jest,msw" ghcr.io/rorar/vibe-kanban-docker:latest
```

**Available tools:**
- `vitest` - Fast Vite-native unit testing framework
- `jest` - Classic unit testing framework
- `msw` - Mock Service Worker for API mocking

**Run tests:**
```bash
npx vitest run          # Run tests once
npx vitest              # Watch mode
npx vitest --coverage   # With coverage
```

### All Tools at Once

Combine multiple runtime installations:

```bash
docker run \
  -e "RUNTIME_AGENTS=claude gemini" \
  -e "RUNTIME_PLAYWRIGHT_BROWSERS=chromium firefox" \
  -e "RUNTIME_TESTING_TOOLS=vitest jest" \
  ghcr.io/rorar/vibe-kanban-docker:latest
```

### OpenAI Codex

1. Authenticate on the host (once):
   ```bash
   npm install -g @openai/codex
   codex
   ```
   This creates `~/.codex/config.toml`.
2. The container mounts `~/.codex` → `/root/.codex`, so the Codex CLI and Vibe can use the same credentials.
3. Prefer API keys? Uncomment `OPENAI_API_KEY` in `.env` and restart Compose.

### GitHub CLI

- Mounts `~/.config/gh` so existing `gh auth login` sessions carry through.
- Run inside the container:
  ```bash
  docker compose exec -e BROWSER=false vibe gh auth status
  ```
  to confirm, or trigger a new device flow without a browser.
- PAT tokens work too—set `GH_TOKEN` or `GITHUB_TOKEN` in `.env`.

### Docker CLI

- The container includes `docker-ce-cli` and the compose plugin.
- The host socket is mounted at `/var/run/docker.sock`, so you can run Docker commands from inside:
  ```bash
  docker compose exec vibe docker ps
  ```

---

## 🧱 Project Layout

| Path | Purpose |
|------|---------|
| `Dockerfile` | Node 22 LTS image with Codex, gh CLI, Docker CLI, build tools. |
| `docker-compose.yml` | Wires up the Vibe service, volumes, and ports. |
| `examples/.env.example` | Optional environment overrides (tokens, git identity). |
| `examples/Dockerfile.local.example` | Template for local-only Dockerfile overlay (copy → `Dockerfile.local`). |
| `examples/docker-compose.local.yml.example` | Template for local Docker Compose overrides (copy → `docker-compose.local.yml`). |
| `data/vibe` | Persisted Vibe state (`config.json`, `db.sqlite`). |
| `data/work` | Workspace mounted to `/work` inside the container. |

> Need multiple repos? Add extra mounts under `volumes:` in `docker-compose.yml`.

---

## ⚙️ Configuration Notes

- The container runs as root. To match host file ownership add `user: "${UID}:${GID}"` under the `vibe` service.
- Git author defaults can be overridden through `.env` or Compose environment entries.
- The Vibe app binds to the port in `PORT`; defaults to `8085` here.
- `.dockerignore` allows this Dockerfile while excluding other generated artifacts.
- Vibe state lives in `data/vibe`; back it up if you rotate containers.
- Set `LOCAL_UID`/`LOCAL_GID` in `.env` so container processes match host ownership (avoids git repo ownership warnings).

---

## 🧪 Health Checks

After the stack is up, verify integrations:

```bash
docker compose exec vibe codex --version
docker compose exec vibe gh auth status
docker compose exec vibe docker version
```

These commands confirm the Codex CLI, GitHub CLI, and Docker CLI are ready inside the container.

---

## 🛠️ Development Tips

- Use `docker compose logs -f vibe` to watch the Vibe server output.
- Restart quickly with `docker compose restart vibe`.
- For a fresh Codex or GitHub login, clear the corresponding volume on the host (`~/.codex`, `~/.config/gh`).
- To run other local repos through the same container, mount them into `/work` or symlink inside the container.

---

## ❓ Troubleshooting

- **Port already in use** – change the host port mapping in `docker-compose.yml`.
- **Codex login prompts** – ensure `~/.codex` isn't empty and permissions are readable.
- **GitHub CLI says unauthenticated** – run `gh auth login` inside the container or set `GH_TOKEN`.
- **Docker commands fail** – confirm Docker Desktop (or dockerd) is running on the host and the socket mount exists.

---

## 🔄 Auto-Update (GitHub Actions)

This repository uses GitHub Actions to automatically rebuild the Docker image when a new version of vibe-kanban is released on npm:

- **Scheduled checks**: Every 6 hours
- **Manual trigger**: Use "Sync with Upstream" workflow with `force_rebuild: true`
- **Update detection**: Compares npm version with the latest git tag

### Available Docker Tags

| Tag | Description |
|-----|-------------|
| `latest` | Always points to the most recent version |
| `0.x.x` | Specific semver version (e.g., `0.1.44`) |
| `0.x` | Major.minor alias (e.g., `0.1`) |
| `0` | Major version alias |
| `sha-<hash>` | Git commit SHA |
| `master` | Current master branch |

### UnRAID

Use the template with:
```
ghcr.io/rorar/vibe-kanban-docker:latest
```

The image digest changes on every update, enabling UnRAID's "Update Available" detection.

#### UnRAID Template

A full UnRAID template is available at:
https://raw.githubusercontent.com/rorar/unraid-templates/main/templates/vibe-kanban.xml

Features:
- Web UI on port 8085
- Persistent storage for data, cache, and worktrees
- SSH keys and GitHub CLI config passthrough
- Docker-in-Docker support via socket mount
- Configurable git author identity
- Advanced API key configuration

See the [unraid-templates repository](https://github.com/rorar/unraid-templates) for the latest version.

---

## 📚 References

- [Vibe Kanban Docs](https://www.vibekanban.com/docs/getting-started)
- [OpenAI Codex CLI](https://developers.openai.com/codex/cli)
- [GitHub CLI Manual](https://cli.github.com/manual/)
- [Docker Compose](https://docs.docker.com/compose/)
