# Smart Home - Home Assistant + Jarvis

Docker-based smart home setup running Home Assistant and OpenClaw (AI assistant) on an Intel NUC.

## Structure
```
homeassistant/
├── docker-compose.yml          # All services: HA, Matter, OpenClaw, Dashboard
├── config/                     # HA config (submodule -> homeassistant-config)
├── openclaw-data/              # OpenClaw config + workspace (gitignored, contains secrets)
├── openclaw-workspace/         # OpenClaw managed workspace (gitignored)
├── dashboard/                  # Planning dashboard (static HTML)
│   ├── index.html              # Floor plan, projects, architecture diagrams
│   ├── nginx.conf              # Nginx config for serving
│   └── apple-touch-icon.png    # PWA icon
├── git-backup.sh               # Backup script with AI commit messages
├── redact-openclaw-config.sh   # Strips secrets from OpenClaw config
├── openclaw.config.bkp         # Sanitized OpenClaw config (secrets removed)
└── README.md
```

## Services

| Service | Image | Purpose |
|---------|-------|---------|
| homeassistant | ghcr.io/home-assistant/home-assistant | Smart home hub |
| matter-server | ghcr.io/home-assistant-libs/python-matter-server | Matter/Thread support |
| openclaw-gateway | ghcr.io/openclaw/openclaw | AI assistant (Jarvis) |
| dashboard | nginx:alpine | Planning dashboard on port 8444 |

## Jarvis (OpenClaw)

Family AI assistant connected via Telegram. Responds to messages in the family group chat.

- **Model:** Gemini 2.5 Pro (primary), Gemini 2.5 Flash (failover)
- **Channel:** Telegram bot in family group (no @mention required)
- **Personality:** Bilingual Hebrew/English, concise, proactive
- **Config:** openclaw-data/openclaw.json (gitignored) -> sanitized copy in openclaw.config.bkp
- **Workspace:** openclaw-data/workspace/ (SOUL.md, USER.md, IDENTITY.md, memory)

### Key Config Notes

- autoSelectFamily: false -- Required to prevent IPv6 timeout freezing the gateway (Node 22+ issue)
- bind: lan -- Required for Tailscale remote access
- groupPolicy: allowlist -- Only whitelisted groups and users can interact
- Telegram group IDs change silently when groups migrate to supergroups. If bot stops responding in group but works in DMs, verify the group ID

## Planning Dashboard

Static HTML dashboard served via nginx. Accessible via Tailscale Funnel.

- Architecture diagrams and protocol flows
- Room-by-room device inventory with floor plan
- Project tracking (lighting, robot garage, climate, security, fans, smart glass)

## Git Backup

Nightly automated backup at 3:17 AM via HA automation. Uses Gemini Flash to generate commit messages.

```bash
./git-backup.sh --help        # Show usage
./git-backup.sh               # Auto-commit with AI message
./git-backup.sh --dry-run     # Preview without committing
./git-backup.sh --skip-ai -m "message"          # Manual message
./git-backup.sh --skip-ai --file /tmp/msg.txt   # Message from file
```

## Quick Start
```bash
git clone --recurse-submodules git@github.com:tomereli/homeassistant.git
cd homeassistant
docker compose up -d
```

## Repos

- [tomereli/homeassistant](https://github.com/tomereli/homeassistant) -- This repo (docker-compose, scripts)
- [tomereli/homeassistant-config](https://github.com/tomereli/homeassistant-config) -- HA config (submodule, auto-pushed nightly)
