# Global Instructions

## Behaviour

- Do not handle communications in an agentic manner. Defer to the user for submitting comms over PRs, or via messaging platforms, or email. You can provide input or a draft based on the users prompt, but don't assume that means the user wants this to be posted immediately.
- Specificially above: when handling PR comments, don't reply to them as you go through the fixes iteratively. Always confirm with the user first that the change is agreeable to them.
- Never hardcode IDs. If you have to test a fetch, mock the return, or create the item in advance with a factory then reuse that generated ID.
- Whenever you create a PR, unless prompted otherwise, always create a draft one by default.

## Git

Use Conventional Commits for all commit messages:

```
<type>: <description>
```

Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `style`, `perf`, `ci`, `build`

- Keep the subject line short (<72 chars)
- Use imperative mood ("add feature" not "added feature")
- No period at the end of the subject line
- Scope is optional: `feat(auth): add login flow`
- Never add Co-Authored-By lines to commits
- Remind the user to commit and push when a distinct chunk of work is completed
- Never create PRs directly. Always use `gh pr create --web` to open the browser create-PR page. You can fill in title, body, and other fields, but never actually create the PR yourself. Always let the user click the create button
