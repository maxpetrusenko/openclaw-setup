# Chapter 9: Node Network (Mobile & Remote)

## Why It Matters

Nodes make OpenClaw a multi-device operator instead of a single-machine tool. They extend automation into cameras, locations, notifications, and remote command execution.

## Core Ideas

- Nodes expose remote capabilities: commands, camera, screen, location, notifications.
- Node status and capability discovery should precede action.
- Camera and screen capture enable monitoring and evidence collection.
- Location polling enables context-aware routines like arrival or away modes.
- Remote command execution turns nodes into distributed monitors and operators.

## Patterns To Keep

- Capability check before using a node.
- Polling plus state file for location-triggered routines.
- Remote command batches for distributed health checks.
- Native device notifications for urgent cases that should bypass chat channels.

## What To Adopt In OpenClaw

- Node inventory doc with capabilities and trust level.
- State-file pattern for presence and location automations.
- Clear separation between passive sensing nodes and command-execution nodes.
- Remote health-check recipes for server or workstation fleets.

## Risks / Limits

- Location and camera access raise privacy stakes quickly.
- Remote command execution on nodes expands blast radius.
- Node connectivity is inherently flaky across networks and sleeping devices.

## Open Questions

- Which devices should be first-class nodes in this repo’s operator model?
- Do we want different approval rules for sensing vs remote command actions?
