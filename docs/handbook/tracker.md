# Handbook Tracker

Status legend:
- `queued`
- `reading`
- `done`
- `needs revisit`

## Chapters

| Item | Status | Note | Short takeaway | Next action |
| --- | --- | --- | --- | --- |
| Chapter 0: Getting Started | `done` | `docs/handbook/chapters/00-getting-started.md` | Install is only real after gateway, workspace, and first end-to-end task all pass. | Turn setup into a local onboarding checklist. |
| Chapter 1: The Age of Personal Automation | `done` | `docs/handbook/chapters/01-age-of-personal-automation.md` | Natural language changes the interface, not the need for clear specs and stable loops. | Use this framing in product and protocol docs. |
| Chapter 2: OpenClaw Architecture | `done` | `docs/handbook/chapters/02-openclaw-architecture.md` | Channel, gateway, agent, tool, world is the core mental model. | Add a current-architecture doc or diagram. |
| Chapter 3: File & Code Automation | `done` | `docs/handbook/chapters/03-file-and-code-automation.md` | Files and artifacts are the real connective tissue of automation. | Standardize artifact trees and validation steps. |
| Chapter 4: Web Automation | `done` | `docs/handbook/chapters/04-web-automation.md` | Use the lightest working web method first; escalate to browser only when needed. | Add method-selection guidance for API, fetch, and browser. |
| Chapter 5: Communication Automation | `done` | `docs/handbook/chapters/05-communication-automation.md` | Messaging is part of the control plane and needs policy, not improvisation. | Write a channel policy doc. |
| Chapter 6: Time-Based Automation (Cron) | `done` | `docs/handbook/chapters/06-time-based-automation-cron.md` | Cron needs canaries, idempotency, heartbeat checks, and timezone discipline. | Standardize cron history and heartbeat patterns. |
| Chapter 7: Multi-Agent Orchestration | `done` | `docs/handbook/chapters/07-multi-agent-orchestration.md` | Router, artifacts, gates, and RALPH matter more than “more agents.” | Formalize control-plane roles and gate files. |
| Chapter 8: Memory & Context Management | `done` | `docs/handbook/chapters/08-memory-and-context-management.md` | Identity, memory, daily logs, and project context are the durable brain. | Define the memory stack for OpenClaw workspaces. |
| Chapter 9: Node Network (Mobile & Remote) | `done` | `docs/handbook/chapters/09-node-network-mobile-and-remote.md` | Nodes extend the control plane into devices and sensors with higher trust cost. | Define first-node policy and capability boundaries. |
| Chapter 10: Browser Agent Deep Dive | `done` | `docs/handbook/chapters/10-browser-agent-deep-dive.md` | Browser control is special-case infrastructure: snapshot first, choose profile deliberately, fall back to APIs when sites fight back. | Write browser worker policy and shadow-mode form-submit rules. |
| Chapter 11: Business Automation | `done` | `docs/handbook/chapters/11-business-automation.md` | Serious work needs project artifacts, quick-path vs full-path routing, and release gates. | Standardize project artifact tree and gate summary files. |
| Chapter 12: Creative Workflows | `done` | `docs/handbook/chapters/12-creative-workflows.md` | Automate logistics around creative work, not taste itself. | Define content workflow states and draft package format. |
| Chapter 13: Personal Life Automation | `done` | `docs/handbook/chapters/13-personal-life-automation.md` | Personal automation works best as compact briefs, guided logging, and prep generation. | Decide which personal loops belong in the first operator stack. |
| Chapter 14: Designing Your Stack | `done` | `docs/handbook/chapters/14-designing-your-stack.md` | Start small, automate only stable loops, choose architecture by error cost and frequency. | Create automation intake rubric for future workflows. |
| Chapter 15: Troubleshooting & Optimization | `done` | `docs/handbook/chapters/15-troubleshooting-and-optimization.md` | Reliability comes from audits, short context files, least privilege, and repeatable debug moves. | Add monthly audit checklist and debug checklist docs. |

## Appendices

| Item | Status | Note | Short takeaway | Next action |
| --- | --- | --- | --- | --- |
| Appendix A: Tool Reference | `done` | `docs/handbook/appendices/a-tool-reference.md` | Tool semantics define the execution and trust boundary. | Keep a local allowed-tools reference. |
| Appendix B: Skill Library | `done` | `docs/handbook/appendices/b-skill-library.md` | Skills extend capability only if they carry real workflow value. | Review trusted default skills. |
| Appendix C: Resources | `done` | `docs/handbook/appendices/c-resources.md` | Handbook patterns are durable; exact implementation details must be re-verified. | Keep a current-docs allowlist. |
| Appendix D: Automation Cookbook | `needs revisit` | `docs/handbook/appendices/d-automation-cookbook.md` | Recipe bank worth mining into local starter flows. | Extract the best 3 recipes into local docs later. |
| Appendix E: Common Patterns Reference | `done` | `docs/handbook/appendices/e-common-patterns-reference.md` | The handbook’s recurring patterns should become templates, not lore. | Convert top patterns into protocol docs. |
| Appendix F: The Practitioner's Field Guide | `done` | `docs/handbook/appendices/f-practitioners-field-guide.md` | Real implementation questions deserve direct, symptom-driven guidance. | Pull top local debugging prompts from this appendix. |
| Appendix G: Full Chapter Expansions | `needs revisit` | `docs/handbook/appendices/g-full-chapter-expansions.md` | Deep expansion appendix contains shadow mode, local-model, and dev-ops gold. | Extract protocol docs from the expansion patterns. |
| Appendix H: Extended Troubleshooting Reference | `done` | `docs/handbook/appendices/h-extended-troubleshooting-reference.md` | Long-form failure index should feed repo runbooks. | Derive a local top-failures runbook. |
| Appendix I: Glossary | `done` | `docs/handbook/appendices/i-glossary.md` | Shared vocabulary reduces prompt and docs ambiguity. | Decide whether to add a short local glossary. |
| Appendix J: Version Notes | `done` | `docs/handbook/appendices/j-version-notes.md` | Patterns are safer than syntax when the platform evolves. | Mark live-doc verification points in implementation work. |
| Appendix K: Complete Worked Examples | `needs revisit` | `docs/handbook/appendices/k-complete-worked-examples.md` | End-to-end examples are blueprints worth operationalizing selectively. | Choose one example to recreate locally. |
| Appendix L: Rapid Reference — The 50 Most Useful | `done` | `docs/handbook/appendices/l-rapid-reference-50-most-useful.md` | Operator cheat sheets matter when incidents are simple and time-sensitive. | Build a repo-local quick-reference. |
