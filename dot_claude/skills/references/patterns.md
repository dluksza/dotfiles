# macOS Scheduler Patterns & Examples

## Common Scheduling Patterns

### Time-Based Patterns

#### Every N Interval
```bash
# Every 30 seconds
scheduler.py create task-name "command" --interval 30

# Every 5 minutes (300 seconds)
scheduler.py create task-name "command" --interval 300

# Every hour (3600 seconds)
scheduler.py create task-name "command" --interval 3600
```

#### Daily Tasks
```bash
# Daily at 2:30 AM
scheduler.py create backup "rsync -av ~/Documents /backup/" --daily 02:30

# Daily at midnight
scheduler.py create cleanup "rm -rf /tmp/*.tmp" --daily 00:00

# Daily at 6 PM
scheduler.py create report "python3 generate_report.py" --daily 18:00
```

#### Hourly Tasks
```bash
# Every hour at :15
scheduler.py create sync "aws s3 sync ~/data s3://bucket/" --hourly :15

# Every hour at :00
scheduler.py create check "curl https://example.com/health" --hourly :00
```

#### Weekly Tasks
```bash
# Every Monday at 9 AM
scheduler.py create weekly-report "python3 report.py" --weekly monday@09:00

# Every Friday at 5 PM
scheduler.py create backup "tar -czf backup.tar.gz ~/Documents" --weekly friday@17:00
```

### Quick Creation Patterns

Using the `quick_task.py` helper:

```bash
# Run every 30 minutes
quick_task.py create every my-sync "rsync -av ~/src /dest/" 30m

# Run daily at 3 AM
quick_task.py create daily cleanup "find /tmp -mtime +7 -delete" 03:00

# Run on system boot
quick_task.py create on-boot startup-apps "open -a Slack && open -a Mail"
```

## Common Use Cases

### 1. Automated Backups

```python
# Time Machine supplement - backup specific folders
scheduler.py create documents-backup \
  "rsync -av --delete ~/Documents /Volumes/Backup/Documents/" \
  --daily 02:00

# Cloud sync
scheduler.py create cloud-sync \
  "rclone sync ~/Important gdrive:Backup/" \
  --interval 1800  # Every 30 minutes
```

### 2. System Maintenance

```python
# Clear cache files
scheduler.py create clear-cache \
  "rm -rf ~/Library/Caches/*/Cache/*" \
  --weekly sunday@03:00

# Update Homebrew packages
scheduler.py create brew-update \
  "brew update && brew upgrade" \
  --weekly saturday@02:00

# Empty trash
scheduler.py create empty-trash \
  "rm -rf ~/.Trash/*" \
  --daily 04:00
```

### 3. Development Tasks

```python
# Database backup
scheduler.py create db-backup \
  "pg_dump mydb > ~/backups/db_$(date +%Y%m%d).sql" \
  --daily 01:00

# Git auto-commit
scheduler.py create git-autocommit \
  "cd ~/notes && git add . && git commit -m 'Auto-commit' && git push" \
  --interval 3600

# Docker cleanup
scheduler.py create docker-cleanup \
  "docker system prune -f" \
  --daily 05:00
```

### 4. Monitoring & Alerts

```python
# Website monitoring
scheduler.py create check-site \
  "curl -f https://mysite.com || osascript -e 'display notification \"Site is down!\"'" \
  --interval 300  # Every 5 minutes

# Disk space check
scheduler.py create disk-check \
  "df -h / | awk '\$5 > 80 {print \"Disk usage high: \" \$5}'" \
  --hourly :00

# Memory usage alert
scheduler.py create memory-check \
  "vm_stat | grep 'Pages free' | awk '{if (\$3 < 1000) print \"Low memory!\"}'" \
  --interval 600  # Every 10 minutes
```

### 5. Productivity & Automation

```python
# Reminder notifications
scheduler.py create water-reminder \
  "osascript -e 'display notification \"Time to drink water!\" with title \"Health Reminder\"'" \
  --interval 3600  # Every hour

# Screenshot organizer
scheduler.py create organize-screenshots \
  "mv ~/Desktop/Screenshot*.png ~/Pictures/Screenshots/ 2>/dev/null" \
  --daily 23:00

# Download folder cleanup
scheduler.py create downloads-cleanup \
  "find ~/Downloads -mtime +30 -type f -delete" \
  --weekly sunday@22:00
```

## Advanced Patterns

### Conditional Execution

```bash
# Only run if condition is met
scheduler.py create conditional-backup \
  "[ -f /tmp/backup-needed ] && rsync -av ~/data /backup/" \
  --hourly :30

# Run only on weekdays (requires wrapper script)
scheduler.py create weekday-task \
  "[ $(date +%u) -le 5 ] && python3 weekday_script.py" \
  --daily 09:00
```

### Chained Commands

```bash
# Multiple commands in sequence
scheduler.py create multi-step \
  "cd ~/project && npm test && npm build && npm deploy" \
  --daily 03:00

# With error handling
scheduler.py create safe-backup \
  "rsync -av ~/data /backup/ && echo 'Backup complete' || echo 'Backup failed'" \
  --daily 02:00
```

### Output Logging

All tasks automatically log to:
- Standard output: `/tmp/com.user.scheduled.<task-name>.out`
- Standard error: `/tmp/com.user.scheduled.<task-name>.err`

To create custom logging:

```bash
scheduler.py create logged-task \
  "date >> ~/logs/task.log && your-command >> ~/logs/task.log 2>&1" \
  --hourly :00
```

## Troubleshooting

### View Task Status
```bash
# List all scheduled tasks
scheduler.py list

# Get details about specific task
scheduler.py details my-task-name

# View task output
tail -f /tmp/com.user.scheduled.my-task-name.out
```

### Remove Tasks
```bash
# Remove a specific task
scheduler.py remove my-task-name

# Remove all user scheduled tasks (be careful!)
for task in $(scheduler.py list --json | jq -r '.[] | select(.type=="launchd") | .name'); do
  scheduler.py remove "$task"
done
```

### Debug Failed Tasks
```bash
# Check error logs
cat /tmp/com.user.scheduled.task-name.err

# Run task manually to test
launchctl start com.user.scheduled.task-name

# Check if task is loaded
launchctl list | grep com.user.scheduled
```

## Best Practices

1. **Use absolute paths** - Scheduled tasks may not have the same PATH environment
2. **Test commands manually first** - Ensure they work before scheduling
3. **Add error handling** - Use || and && for basic error handling
4. **Log important tasks** - Redirect output to log files for debugging
5. **Set appropriate intervals** - Don't poll too frequently to save resources
6. **Use meaningful names** - Makes management easier
7. **Document complex tasks** - Add comments in wrapper scripts

## Resource Efficiency Tips

- Combine related tasks into single scripts instead of multiple scheduled jobs
- Use longer intervals when possible (hourly vs every minute)
- Avoid heavy operations during peak hours
- Use `nice` command for low-priority tasks: `nice -n 10 your-command`
- Consider using `caffeinate` to prevent sleep during long tasks
