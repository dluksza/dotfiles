---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git restore:*), Bash(git show:*), Bash(git stash:*)
argument-hint: [optional context about changes]
description: Commit staged/unstaged changes following git best practices
---

<instructions>
Commit changes following git commit message best practices.

1. Run in parallel:
   - `git status` (no -uall flag)
   - `git diff` and `git diff --staged`
   - `git log --oneline -5` for style reference

2. Analyze changes. Draft commit message:
   - Subject: imperative mood, ≤50 chars, semantic prefix (feat/fix/refactor/docs/test/chore)
   - Body: wrap at 72 chars, explain WHY not WHAT
   - Reference $ARGUMENTS context if provided

3. Stage relevant files, commit using HEREDOC format, verify with `git status`

Do NOT push. Do NOT commit secrets (.env, credentials).
</instructions>

<context>
User-provided context: $ARGUMENTS
</context>
