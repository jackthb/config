---
name: build-feature
description: Build a new feature using a pre-configured agent team — architect-surveyor, designer, and verifier. Use when the user asks to build, add, or implement a feature ("build a todo list", "add auth", "implement X") and wants collaborative parallel exploration rather than a single-session implementation. Skip for trivial one-liners.
---

Build the feature the user described using an agent team. You are the lead and the implementer.

# Preconditions

- Agent teams must be enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`). If `TeamCreate` isn't available, tell the user and stop.
- If the feature is trivial (< ~20 lines, no new concepts, obvious one-liner), skip the team and just do it — tell the user why.

# Workflow

## 1. Survey — serial, blocking

Create the team. Spawn ONE teammate from the `feature-architect` agent type and ask:

> Does `$FEATURE` already exist in this codebase, fully or partially? Report with file:line references. Check dependencies too.

Wait for the architect's answer before spawning anyone else.

- **If it already exists**: report to the user, ask whether to reuse, extend, or build anyway. Don't spawn the rest of the team until they confirm.
- **If partial**: note what's reusable — this informs the design.
- **If nothing**: continue.

## 2. Design + test plan — parallel

Spawn two teammates in a single turn:

- `feature-designer` named `designer`: "Propose the interface shape for $FEATURE. Match existing conventions (the architect's survey is in the task list). Keep scope minimal. Post your proposal when ready."
- `feature-verifier` named `verifier`: "Plan the test strategy for $FEATURE based on the designer's proposal. You'll run these tests after implementation."

Review the designer's proposal yourself as lead. If you see scope creep, missing failure modes, or maintenance red flags, push back directly before implementation starts.

## 3. Implement — you, the lead

Write the code yourself once the design is settled. Don't delegate implementation to teammates unless the feature cleanly partitions across files (frontend/backend/tests) — in that case, assign per-file ownership so no two teammates touch the same file.

While implementing, keep the team's context intact; they can answer questions via messages if you hit something ambiguous.

## 4. Verify — hand off to verifier

Tell `verifier` to run their planned tests plus exercise the feature end-to-end. Wait for their report. If they find issues, fix them yourself and re-verify.

## 5. Clean up

Once verification passes and the user is satisfied:

1. Shut down each teammate (send shutdown requests through the lead).
2. Clean up the team via `TeamDelete`.

Never ask a teammate to clean up — only the lead should.

# Guardrails

- **Roles are fixed**: designer does not write production code. Verifier does not modify production code to make tests pass.
- **Don't let the lead drift into waiting**: if teammates stall, message them directly or re-task.
- **Pre-approve common permissions** before spawning to reduce permission-prompt friction — teammate prompts bubble up to you.
- **Small team by design**: three roles (architect, designer, verifier) cover most features. Resist the urge to add more.
