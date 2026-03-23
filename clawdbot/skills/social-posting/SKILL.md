---
name: social-posting
description: Create social creatives and publish via GetLate across multiple platforms with per-platform constraints.
metadata: {"clawdbot":{"emoji":"📣","os":["linux","darwin"],"requires":{"bins":["python3","curl"]}}}
---

# Social Posting

Use this skill when you need to generate social assets and publish/schedule posts via GetLate.

## What It Handles

- Image asset generation:
  - Feed landscape: `1200x675`
  - Feed square: `1080x1080`
  - IG Story vertical: `1080x1920` with short overlay text
- Optional Gemini-assisted copy generation (uses keys from `.env`)
- GetLate publish workflow:
  - Upload media via `/v1/media/presign`
  - Create post via `/v1/posts`
  - Poll status and write a run log
  - Return connect URLs for missing/inactive platforms

## Environment

Set at least:

```bash
export GETLATE_API_KEY=...
```

Optional Gemini keys (either works):

```bash
export Gemini_token_max=...
export gemini_token_turkey=...
```

## 1) Generate Assets

```bash
python3 {baseDir}/scripts/generate_social_assets.py \
  --topic "Gemini 3.1 Pro" \
  --output-dir ./clawdbot/tmp/social-assets
```

## 2) Publish Campaign

```bash
python3 {baseDir}/scripts/getlate_campaign.py \
  --topic "Gemini 3.1 Pro" \
  --assets-manifest ./clawdbot/tmp/social-assets/latest/manifest.json \
  --platforms linkedin,facebook,instagram,x,tiktok,youtube \
  --publish-now \
  --attempt-inactive
```

## Notes

- Instagram Story posts are created with `platformSpecificData.contentType=story` and single vertical media.
- `x` is normalized to GetLate platform `twitter`.
- If a platform is not connected, the script returns OAuth connect URLs instead of failing silently.
- If X returns BYOK requirement, the script reports it in the log.
