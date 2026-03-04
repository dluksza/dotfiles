---
name: macos-scheduler
description: Manage scheduled and repeating tasks on macOS using launchd and cron. Use when users ask about scheduling tasks, creating repeating actions, automating commands, setting up cron jobs, or managing background tasks on Mac. Triggers include "schedule a task", "run every", "automate", "repeat action", "cron job", "background task", "periodic execution", "run at startup", "daily/hourly/weekly task".
---

# macOS Scheduler

Efficient task scheduling and automation for macOS using native scheduling systems.

## Quick Start

List all scheduled tasks:
```bash
python3 scripts/scheduler.py list
```

Create a repeating task:
```bash
# Run every hour
python3 scripts/scheduler.py create my-task "echo 'Hello'" --interval 3600

# Run daily at 2 AM
python3 scripts/scheduler.py create backup "rsync -av ~/Documents /backup/" --daily 02:00

# Quick creation for common patterns
python3 scripts/quick_task.py create every sync-task "your-command" 30m
```

## Core Operations

### List Tasks
```bash
scripts/scheduler.py list [--json]
```
Shows all scheduled tasks from launchd and cron.

### Create Task
```bash
scripts/scheduler.py create <name> "<command>" [schedule-options]
```

Schedule options:
- `--interval N`: Run every N seconds
- `--daily HH:MM`: Run daily at specified time
- `--hourly :MM`: Run every hour at minute MM
- `--weekly DAY@HH:MM`: Run weekly on DAY at time
- `--startup`: Run at system boot

### Quick Task Creation
```bash
scripts/quick_task.py create <type> <name> "<command>" [params]
```

Types: `every`, `daily`, `hourly`, `weekly`, `on-boot`

The quick_task script accepts human-friendly intervals:
- `30s` (30 seconds)
- `5m` (5 minutes)  
- `2h` (2 hours)
- `1d` (1 day)

### Remove Task
```bash
scripts/scheduler.py remove <task-name>
```

### Task Details
```bash
scripts/scheduler.py details <task-name>
```

## Implementation Strategy

1. **Identify the scheduling need** from user's request
2. **Choose appropriate schedule type**:
   - Frequent checks (monitoring): Use interval scheduling
   - Daily maintenance: Use calendar scheduling
   - One-time future tasks: Not supported (suggest using `at` command)
3. **Use quick_task.py for simple patterns** when user asks for common scheduling
4. **Refer to patterns.md** for complex scheduling examples

## Key Features

- **Token Efficient**: Scripts handle the heavy lifting, minimal context needed
- **Native Integration**: Uses macOS launchd for reliability
- **Smart Suggestions**: quick_task.py suggests schedules based on task description
- **Automatic Logging**: All tasks log to `/tmp/com.user.scheduled.<name>.{out,err}`
- **Safe Operations**: Tasks run in user space, no sudo required

## Common Patterns

For detailed examples and patterns, read:
```bash
cat references/patterns.md
```

This includes patterns for:
- Automated backups
- System maintenance  
- Development workflows
- Monitoring & alerts
- Productivity automation

## Best Practices

1. **Test commands manually first** before scheduling
2. **Use absolute paths** in commands (scheduled tasks have limited PATH)
3. **Add error handling** with `&&` and `||` operators
4. **Choose appropriate intervals** to avoid resource waste
5. **Name tasks descriptively** for easy management

## Troubleshooting

View task output:
```bash
tail -f /tmp/com.user.scheduled.<task-name>.out
tail -f /tmp/com.user.scheduled.<task-name>.err
```

Check if task is running:
```bash
launchctl list | grep com.user.scheduled.<task-name>
```

## Notes

- Tasks persist across reboots (stored in ~/Library/LaunchAgents/)
- All tasks run as the current user
- For system-wide tasks, different approach needed (requires admin)
- Tasks continue running even when Terminal is closed
