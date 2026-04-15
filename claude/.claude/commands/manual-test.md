---
name: manual-test
description: Generate a manual testing checklist for the current branch before merging
allowed-tools: Bash(git diff *), Bash(git log *), Bash(git branch *), Bash(gh pr *)
---

You are generating a manual testing checklist for a developer about to merge their branch.

1. Run `git log main..HEAD --oneline` to see commits in scope.
2. Run `git diff main...HEAD` to understand all changes.
3. If a PR exists, run `gh pr view --json title,body` for context.

Analyse the changes and produce a prioritised manual testing checklist. For each item:
- Describe the exact action to take (what to click, what API to call, what data to set up)
- Describe the expected outcome
- Flag any data setup required (e.g. specific account types, feature flags, permissions)

Group by area (e.g. happy path, edge cases, permissions/auth, error states, data integrity).

Focus on:
- The primary flows directly changed
- Regression risks — adjacent functionality that could have broken
- Permission/auth boundaries (different user roles, account types)
- Edge cases implied by the code (empty states, limits, concurrency)
- Any DB migrations or data changes that need verifying

Keep it actionable. Skip anything clearly covered by automated tests unless it's high risk.
