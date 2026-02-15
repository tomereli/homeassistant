# Home Assistant Setup

My Home Assistant Docker setup with automated Git backups.

## Structure
```
homeassistant/
├── docker-compose.yml    # HA container config
├── config/               # HA config (submodule → homeassistant-config)
```

## Features

- Home Assistant in Docker with auto-restart
- Git installed on container startup for automated backups
- Config tracked in separate repo via submodule

## Quick Start
```bash
# Clone with submodule
git clone --recurse-submodules git@github.com:tomereli/homeassistant.git

# Start
cd homeassistant
docker-compose up -d
```

## Config Submodule

The `config/` folder is a Git submodule pointing to [homeassistant-config](https://github.com/tomereli/homeassistant-config). 

Home Assistant automatically commits and pushes config changes nightly using AI-generated commit messages.
