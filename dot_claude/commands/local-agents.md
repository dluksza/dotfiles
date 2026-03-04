---
name: local-agents
model: haiku
---

# Local agents

## Workflow

- find all markdown files in @.claude/agents/
- for each file:
  - remember its name without the `.md` extension
  - read first 7 lines, and find one starting from `description:` and remember the value of if
- print all of the found agents in the following format:

```
<agent name>: <agent description>
```

- output only the above text, nothing more or less. Only the agent name and description
