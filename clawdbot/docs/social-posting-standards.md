---
summary: "Operational standards for multi-platform social posting with OpenClaw + GetLate."
read_when:
  - Building or running social posting automations
  - Deciding single-agent vs multi-agent posting workflows
---

# Social Posting Standards

## Platform Rules (Default)

- Instagram Story:
  - format: `1080x1920` (9:16)
  - media: single image/video
  - text: very short overlay only
  - API setting: `platformSpecificData.contentType=story`
- X (Twitter):
  - keep primary copy <= 260 chars
  - media optional but recommended
  - note: current GetLate account requires BYOK
- LinkedIn/Facebook:
  - image + concise long-form caption allowed
  - avoid link-only low-context posts
- TikTok:
  - image carousel or video
  - include platform-specific settings (privacy + consent flags)
- YouTube:
  - requires video media
  - image-only posts are not valid for standard upload flow

## Asset Pack (Per Topic)

Generate all three each run:
- `feed_square.png` (1080x1080)
- `feed_landscape.png` (1200x675)
- `story_vertical.png` (1080x1920)

## Copy Pack (Per Topic)

- `caption_long` for LinkedIn/Facebook
- `caption_short` for X/TikTok
- `story_overlay` for IG Story
- max 5 hashtags

## Run Sequence

1. Generate assets + copy.
2. Validate account status (`/v1/accounts`).
3. Build connect URLs for missing platforms.
4. Publish active platforms.
5. Log failures with raw API response and account/platform mapping.
6. Retry only failed platforms after account/connect fixes.

## Single vs Multi-OC Recommendation

Use multi-OC when posting daily or to 4+ platforms:
- OC 1: Creative (assets + copy generation)
- OC 2: Publisher (GetLate upload + publish + retries)
- OC 3: QA/Compliance (length checks, story format checks, failure triage)

Use single OC for ad-hoc manual campaigns.

## Required Logs

Every campaign run must save:
- requested platforms
- selected targets (active/inactive/missing)
- connect URLs for missing platforms
- create post response
- final platform statuses
- public post URLs (when available)
