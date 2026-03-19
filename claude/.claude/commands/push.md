Commit all staged and unstaged changes, then push to the remote branch.

Steps:
1. Run `git status` to see what changed (never use -uall flag)
2. Run `git diff` to see staged and unstaged changes
3. Run `git log --oneline -5` to see recent commit style
4. Stage the relevant changed files (prefer specific filenames over `git add -A`)
5. Write a concise commit message that describes the "why". Do NOT append any Co-Authored-By line.
6. Commit using a HEREDOC for the message
7. Push to the current branch with `git push`
8. Report the result
