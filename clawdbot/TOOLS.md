---
summary: "Workspace template for TOOLS.md"
read_when:
  - Bootstrapping a workspace manually
---

# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.

### GitHub

- Bot account: openclawb0t
- Org: appDevelopment-tech
- Git identity: OpenClaw Bot <openclaw@maxpetrusenko.com>
- SSH key: ~/.ssh/id_ed25519 (ed25519)
- Tested repos: Geo-analyzer, maxpetrusenko.com (read-only confirmed)
- Write access: Pending (need team permission update)

### Skills Quick Reference

- **Coding:** code v1.1.0
- **Research:** search-1 v1.0.1, literature-search v1.0.3, web-search-exa v1.0.1
- **Planning:** todo v1.1.0, planning-with-files v1.2.0
- **Calendar:** calendar v1.0.0, coordinate-meeting v1.0.1
- **Trading:** base-trader v1.1.1
- **Home:** smart-home-energy-saver v1.0.0, homeassistant-assist v1.1.0
- **Comms:** imsg v1.0.0, agentic-calling v0.1.0
- **Social:** social-posting v0.1.0 (GetLate + asset generation)

### Apple Watch (Shortcut Bridge)

- Install path: Apple Watch -> iPhone Shortcuts -> SSH -> VPS container
- Host: `187.77.7.226` (user `root`)
- Container: `openclaw-ylld-openclaw-1`
- Shortcut script core:
  - `sudo docker exec -i openclaw-ylld-openclaw-1 sh -lc 'msg="$(cat)"; openclaw agent --agent main --message "$msg"'`
- Full guide: `docs/apple-watch-install.md`

### Notion Integration
- Token: [REDACTED_NOTION_TOKEN] (read-only; store as env var `NOTION_TOKEN`, not in files)
- Helper script: /data/.openclaw/workspace/tools/notion/notion.sh
- Commands:
  - `list-databases` — List accessible databases
  - `query <db-id>` — Query a specific database
  - `page <page-id>` — Get page content
  - `search <query>` — Search for content
- Note: Token needs to be granted access to specific pages/databases in Notion UI

### Brave Search API

- API Key: [REDACTED_API_KEY] (store as env var `BRAVE_SEARCH_API_KEY`, not in files)
- Quota: 2,000 requests/month (free tier)
- Usage: For web_search tool calls

### Resend Email API

- API Key: [REDACTED_API_KEY] (store as env var `RESEND_API_KEY`, not in files)
- Usage: For sending emails via API
