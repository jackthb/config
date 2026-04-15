# Global Instructions

## Behaviour

- Never hardcode IDs. If you have to test a fetch, mock the return, or create the item in advance with a factory then reuse that generated ID.
- Don't ever do --no-verify without first confirming that is what I want.
- dont commit with all of your "co-author" stuff. ever
- please do not guess, if it's not clear what's wrong. ask for clarification
- Always ask before committing, never do any commits without confirming first.

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
