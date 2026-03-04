#!/usr/bin/env python3
"""
Quick task creator for common scheduling patterns.
Provides simple interface for creating scheduled tasks.
"""

import sys
import json
import subprocess
from pathlib import Path

def quick_create(task_type, name, command, *args):
    """
    Create a scheduled task with minimal parameters.
    
    Examples:
    - quick_create('every', 'backup', 'rsync -av ~/Documents /backup/', '1h')
    - quick_create('daily', 'cleanup', 'rm -rf /tmp/*.tmp', '02:00')
    - quick_create('on-boot', 'startup', 'open -a Safari')
    """
    
    scheduler_path = Path(__file__).parent / 'scheduler.py'
    
    if task_type == 'every':
        # Parse interval (e.g., '30s', '5m', '1h', '2d')
        interval_str = args[0] if args else '1h'
        seconds = parse_interval(interval_str)
        cmd = ['python3', str(scheduler_path), 'create', name, command, 
               '--interval', str(seconds)]
    
    elif task_type == 'daily':
        # Daily at specific time
        time = args[0] if args else '00:00'
        cmd = ['python3', str(scheduler_path), 'create', name, command,
               '--daily', time]
    
    elif task_type == 'hourly':
        # Every hour at specific minute
        minute = args[0] if args else ':00'
        if not minute.startswith(':'):
            minute = ':' + minute
        cmd = ['python3', str(scheduler_path), 'create', name, command,
               '--hourly', minute]
    
    elif task_type == 'weekly':
        # Weekly on specific day and time
        day_time = args[0] if args else 'monday@09:00'
        cmd = ['python3', str(scheduler_path), 'create', name, command,
               '--weekly', day_time]
    
    elif task_type in ['on-boot', 'startup', 'boot']:
        # Run at system startup
        cmd = ['python3', str(scheduler_path), 'create', name, command,
               '--startup']
    
    else:
        return f"Unknown task type: {task_type}"
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout if result.returncode == 0 else result.stderr


def parse_interval(interval_str):
    """Parse interval string to seconds."""
    interval_str = interval_str.lower()
    
    multipliers = {
        's': 1,
        'm': 60,
        'h': 3600,
        'd': 86400,
        'w': 604800
    }
    
    # Extract number and unit
    import re
    match = re.match(r'(\d+)([smhdw])?', interval_str)
    if not match:
        return 3600  # Default to 1 hour
    
    number = int(match.group(1))
    unit = match.group(2) or 's'
    
    return number * multipliers.get(unit, 1)


def suggest_schedule(description):
    """
    Suggest a schedule based on task description.
    Returns a dict with suggested schedule type and parameters.
    """
    
    keywords = {
        'backup': {'type': 'daily', 'params': ['02:00'], 
                  'reason': 'Backups typically run during off-hours'},
        'cleanup': {'type': 'daily', 'params': ['03:00'],
                   'reason': 'Cleanup tasks run in early morning'},
        'sync': {'type': 'every', 'params': ['30m'],
                'reason': 'Sync tasks often run frequently'},
        'report': {'type': 'weekly', 'params': ['monday@09:00'],
                  'reason': 'Reports often generated weekly'},
        'monitor': {'type': 'every', 'params': ['5m'],
                   'reason': 'Monitoring requires frequent checks'},
        'update': {'type': 'daily', 'params': ['04:00'],
                  'reason': 'Updates run during low-activity hours'},
        'check': {'type': 'every', 'params': ['15m'],
                 'reason': 'Check tasks run periodically'},
        'startup': {'type': 'on-boot', 'params': [],
                   'reason': 'Startup tasks run at boot'},
        'boot': {'type': 'on-boot', 'params': [],
                'reason': 'Boot tasks run at system start'}
    }
    
    description_lower = description.lower()
    
    for keyword, config in keywords.items():
        if keyword in description_lower:
            return config
    
    # Default suggestion
    return {
        'type': 'daily',
        'params': ['00:00'],
        'reason': 'Default to daily execution at midnight'
    }


def main():
    if len(sys.argv) < 2:
        print("Quick Task Creator")
        print("=" * 40)
        print("\nUsage patterns:")
        print("  Create task:     quick_task.py create <type> <name> <command> [params]")
        print("  Suggest schedule: quick_task.py suggest <description>")
        print("\nTask types:")
        print("  every    - Run every N seconds/minutes/hours (e.g., '30s', '5m', '1h')")
        print("  daily    - Run daily at specific time (e.g., '14:30')")
        print("  hourly   - Run every hour at minute (e.g., ':15')")
        print("  weekly   - Run weekly (e.g., 'tuesday@10:00')")
        print("  on-boot  - Run at system startup")
        print("\nExamples:")
        print("  quick_task.py create every my-backup 'rsync -av ~/Documents /backup/' 1h")
        print("  quick_task.py create daily cleanup 'rm -rf /tmp/*.tmp' 02:00")
        print("  quick_task.py suggest 'backup my documents'")
        sys.exit(0)
    
    action = sys.argv[1]
    
    if action == 'create' and len(sys.argv) >= 5:
        task_type = sys.argv[2]
        name = sys.argv[3]
        command = sys.argv[4]
        params = sys.argv[5:] if len(sys.argv) > 5 else []
        
        result = quick_create(task_type, name, command, *params)
        print(result)
    
    elif action == 'suggest' and len(sys.argv) >= 3:
        description = ' '.join(sys.argv[2:])
        suggestion = suggest_schedule(description)
        
        print(f"Suggested schedule for '{description}':")
        print(f"  Type: {suggestion['type']}")
        if suggestion['params']:
            print(f"  Parameters: {', '.join(suggestion['params'])}")
        print(f"  Reason: {suggestion['reason']}")
        
        # Show example command
        example_name = description.replace(' ', '_')[:20]
        example_cmd = f"echo 'Running {description}'"
        params_str = ' '.join(suggestion['params'])
        
        print(f"\nExample command:")
        print(f"  quick_task.py create {suggestion['type']} {example_name} '{example_cmd}' {params_str}")
    
    else:
        print("Invalid arguments. Run without arguments for help.")
        sys.exit(1)


if __name__ == '__main__':
    main()
