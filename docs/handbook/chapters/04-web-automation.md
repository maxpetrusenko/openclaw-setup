# Chapter 4: Web Automation

## Why It Matters

Web data is a primary input surface, but the chapter’s real lesson is decision discipline: default to lightweight fetch and search, escalate to browser only when the page forces you.

## Core Ideas

- `web_search` finds candidate sources.
- `web_fetch` is for static HTML, APIs, and cheap extraction.
- Browser is for JS-rendered content, auth, and interactions.
- Dynamic-page extraction needs waits, scrolls, re-checks, and sometimes page-side JS.
- Screenshots and PDFs are useful for monitoring and archiving.
- Web automation fails most often because sites change, throttle, or require auth.

## Patterns To Keep

- Try fetch first, then browser.
- Use freshness and targeted queries for research tasks.
- Extract, normalize, and compare into stored JSON for monitoring jobs.
- Prefer text or markdown extraction modes based on downstream need.
- Store secrets in files, not prompts or scripts.

## What To Adopt In OpenClaw

- A fetch-vs-browser routing rule in core docs.
- Price-monitor and recurring web-check patterns as first-class examples.
- Explicit fallback path when a site becomes too hostile.
- Rate-limiting and auth-handling guidance near web workflows.

## Risks / Limits

- Browser flows become brittle as sites evolve.
- Some sites should not be automated without an API alternative.
- CAPTCHA and anti-bot systems can make workflows economically irrational.

## Open Questions

- Which recurring OpenClaw jobs should stay `web_fetch` only?
- Do we need a shared web-monitoring template for structured comparison tasks?
