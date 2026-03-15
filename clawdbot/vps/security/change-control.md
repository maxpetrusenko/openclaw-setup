# Change Control (External Systems)

This is the rule for anything that mutates external systems (Cloudflare, DNS, deploys, payments, production data).

## Required Workflow

1. Probe current state (read-only).
2. Propose a plan including:
   - exact command(s) or API calls to run
   - what will change (before/after)
   - success checks
   - rollback plan
3. Wait for explicit human approval (a clear "yes" / "approved" for the commands).
4. Execute.
5. Verify outcome and report what changed.

## Never Do Automatically

- DNS edits
- deleting resources
- deploying to production
- rotating credentials
- editing firewall/WAF rules

