# Cloudflare Access (OpenClaw)

Goal: let OpenClaw manage Cloudflare resources (DNS, Pages, Workers, etc.) **safely**.

## Guardrails (Must Follow)

- Read-only first: verify current state before proposing changes.
- Change control: before any mutating Cloudflare action, present:
  - exact command(s) to run
  - expected outcome
  - rollback plan
- Do not execute the mutating command until the human explicitly approves.

## Recommended: Use a Scoped API Token (Not Global Key)

Create a Cloudflare API token with least privilege for what you need.

Typical permissions (choose only what you actually need):
- Account: Cloudflare Pages - Edit
- Account: Workers Scripts - Edit
- Zone: DNS - Edit (for specific zone(s))
- Zone: Zone - Read (often needed for tooling)

## Where To Store Secrets (VPS)

Do not store tokens in repo files.

For the Hostinger OpenClaw Docker deployment, the runtime environment comes from:
- `/docker/openclaw-ylld/.env`

Add:
- `CLOUDFLARE_API_TOKEN=...`
- optionally `CLOUDFLARE_ACCOUNT_ID=...` (needed for some workflows/tools)

Then recreate/restart the container so env vars apply.

## Verification (Read-Only)

After setting the token, verify access (read-only):
- `curl -sS https://api.cloudflare.com/client/v4/user/tokens/verify -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"`
- If using `wrangler`: `wrangler whoami` (requires `CLOUDFLARE_API_TOKEN`)

If verification fails:
- confirm token permissions + which account/zone it targets
- confirm the container was recreated after editing `.env`

