---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*)
argument-hint: [optional context about changes]
description: Commit staged/unstaged changes following git best practices
---

<instructions>
Commit changes following git commit message best practices.

1. Stop if there is nothing to commit. Otherwise run in parallel:
   - `git status` (no -uall flag)
   - `git diff` and `git diff --staged`
   - `git log --oneline -5` for subject style reference

2. Check the changes:
   - If anything is already staged, commit only that. Ask before staging more.
   - Read each untracked file that will be committed. `git diff` does not show new files.
   - Scan the diff and untracked files for secrets (keys, tokens, passwords, .env files, credential files). If you find one, stop and ask.
   - If the changes hold more than one unrelated change, make one commit for each change.

3. Draft the commit message:
   - Subject: imperative mood, ≤50 chars, no trailing period, semantic prefix (feat/fix/refactor/docs/test/chore/perf/style/ci/build/revert)
   - Blank line between subject and body
   - Body: wrap at 72 chars, explain WHY not WHAT
   - Write Subject and Body in Simplified Technical English: short sentences, active voice, simple present or past tense, no idioms, no contractions
   - Use the user-provided context below, if any

4. Stage by file path. Never use `git add -A` or `git add .`. Commit with a HEREDOC message. Never use `--amend` or `--no-verify`. If a hook fails, fix the problem and make a new commit.

5. Verify with `git status` and `git log -1 --stat`.

Do not create branches and do not push. Do not add a `Co-Authored-By` line or any other AI attribution trailer.
</instructions>

<context>
User-provided context: $ARGUMENTS
</context>
