# Appendix B: Skill Library

## Why It Matters
Skills are the extension layer. They package prompts, tools, and domain workflows so the base system does not need to reinvent the same expertise repeatedly.

## Core Ideas
- Skills are installable, removable, and domain-specific.
- Good skills add knowledge delta and decision rules, not generic filler.
- Skills let the control plane stay thin while workflows stay specialized.

## Patterns To Keep
- Prefer skills for repeated specialist work.
- Treat skill choice as part of routing, not an afterthought.
- Keep skill docs short, practical, and explicit about when to use them.

## What To Adopt In OpenClaw
- Map recurring workflows to a small curated skill set.
- Keep skill usage rules close to routing rules.
- Review externally sourced skills before trusting their scripts.

## Risks / Limits
- Skill sprawl can recreate the same complexity problem as tool sprawl.
- Low-quality skills add ceremony without actual leverage.

## Open Questions
- Which internal OpenClaw workflows deserve first-class skills?
- Do we need a skill quality rubric for this repo?
