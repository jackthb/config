---
name: reword
description: Reword the last git commit message
allowed-tools: Bash(git log *), Bash(git commit --amend *)
model: haiku
---

Show the current last commit message with `git log -1 --pretty=%B`.

If the user provided a new message as an argument, use that directly.
Otherwise, suggest an improved message following Conventional Commits: `type(scope): description` and ask the user to confirm or provide their own.

Once confirmed, run `git commit --amend -m "<message>"`.
