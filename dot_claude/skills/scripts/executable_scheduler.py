#!/usr/bin/env python3
"""
macOS Task Scheduler Manager
Efficiently manages scheduled tasks using launchd and cron on macOS.
"""

import os
import sys
import json
import subprocess
import plistlib
from pathlib import Path
from datetime import datetime
import argparse

class MacOSScheduler:
    def __init__(self):
        self.launchd_user_path = Path("~/Library/LaunchAgents").expanduser()
        self.launchd_user_path.mkdir(exist_ok=True)
        
    def list_tasks(self, format_output="table"):
        """List all scheduled tasks from launchd and cron."""
        tasks = []
        
        # Get launchd tasks
        try:
            result = subprocess.run(['launchctl', 'list'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                for line in result.stdout.strip().split('\n')[1:]:
                    parts = line.split('\t')
                    if len(parts) >= 3:
                        pid = parts[0]
                        status = parts[1] 
                        label = parts[2]
                        # Filter to user tasks
                        if 'com.user.scheduled' in label or self._is_user_task(label):
                            tasks.append({
                                'type': 'launchd',
                                'name': label,
                                'status': 'running' if pid != '-' else 'stopped',
                                'pid': pid if pid != '-' else None
                            })
        except Exception as e:
            print(f"Warning: Could not list launchd tasks: {e}", file=sys.stderr)
        
        # Get cron tasks
        try:
            result = subprocess.run(['crontab', '-l'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                for i, line in enumerate(result.stdout.strip().split('\n')):
                    if line and not line.startswith('#'):
                        tasks.append({
                            'type': 'cron',
                            'name': f'cron_job_{i}',
                            'schedule': ' '.join(line.split()[:5]),
                            'command': ' '.join(line.split()[5:])
                        })
        except Exception:
            pass  # No cron tasks
        
        if format_output == "json":
            return json.dumps(tasks, indent=2)
        else:
            return self._format_tasks_table(tasks)
    
    def _format_tasks_table(self, tasks):
        """Format tasks as a readable table."""
        if not tasks:
            return "No scheduled tasks found."
        
        output = ["Scheduled Tasks on macOS", "=" * 50]
        
        launchd_tasks = [t for t in tasks if t['type'] == 'launchd']
        cron_tasks = [t for t in tasks if t['type'] == 'cron']
        
        if launchd_tasks:
            output.append("\nLaunchd Tasks:")
            for task in launchd_tasks:
                status = f"[{task['status']}]"
                pid = f"PID: {task['pid']}" if task.get('pid') else ""
                output.append(f"  • {task['name']} {status} {pid}")
        
        if cron_tasks:
            output.append("\nCron Tasks:")
            for task in cron_tasks:
                output.append(f"  • {task['name']}")
                output.append(f"    Schedule: {task['schedule']}")
                output.append(f"    Command: {task['command']}")
        
        return '\n'.join(output)
    
    def _is_user_task(self, label):
        """Check if a launchd label is a user-created task."""
        user_patterns = ['local.', 'user.', 'custom.']
        return any(pattern in label.lower() for pattern in user_patterns)
    
    def create_launchd_task(self, name, command, schedule_type, schedule_value):
        """Create a launchd task with the given schedule."""
        label = f"com.user.scheduled.{name}"
        plist_path = self.launchd_user_path / f"{label}.plist"
        
        # Build the plist dictionary
        plist = {
            'Label': label,
            'ProgramArguments': self._parse_command(command),
            'RunAtLoad': False,
            'StandardOutPath': f'/tmp/{label}.out',
            'StandardErrorPath': f'/tmp/{label}.err'
        }
        
        # Add schedule based on type
        if schedule_type == 'interval':
            # Run every N seconds
            plist['StartInterval'] = int(schedule_value)
        elif schedule_type == 'calendar':
            # Calendar-based scheduling (daily, weekly, etc.)
            calendar_dict = self._parse_calendar_schedule(schedule_value)
            if calendar_dict:
                plist['StartCalendarInterval'] = calendar_dict
        elif schedule_type == 'startup':
            plist['RunAtLoad'] = True
        
        # Write the plist file
        with open(plist_path, 'wb') as f:
            plistlib.dump(plist, f)
        
        # Load the task
        subprocess.run(['launchctl', 'load', str(plist_path)], check=True)
        
        return f"Task '{name}' created successfully as {label}"
    
    def _parse_command(self, command):
        """Parse command string into array for ProgramArguments."""
        import shlex
        parts = shlex.split(command)
        
        # Expand shell commands if needed
        if parts[0] in ['sh', 'bash', 'zsh']:
            return parts
        elif '|' in command or '>' in command or '<' in command:
            # Shell features detected, wrap in sh
            return ['/bin/sh', '-c', command]
        else:
            # Direct command
            return parts
    
    def _parse_calendar_schedule(self, schedule_value):
        """Parse calendar schedule string into launchd format."""
        # Format: "daily@14:30" or "weekly@Monday@09:00" or "hourly@:15"
        parts = schedule_value.lower().split('@')
        
        if parts[0] == 'daily' and len(parts) == 2:
            time_parts = parts[1].split(':')
            return {
                'Hour': int(time_parts[0]),
                'Minute': int(time_parts[1]) if len(time_parts) > 1 else 0
            }
        elif parts[0] == 'hourly' and len(parts) == 2:
            minute = int(parts[1].replace(':', ''))
            return {'Minute': minute}
        elif parts[0] == 'weekly' and len(parts) == 3:
            weekday_map = {
                'monday': 1, 'tuesday': 2, 'wednesday': 3,
                'thursday': 4, 'friday': 5, 'saturday': 6, 'sunday': 0
            }
            weekday = weekday_map.get(parts[1], 1)
            time_parts = parts[2].split(':')
            return {
                'Weekday': weekday,
                'Hour': int(time_parts[0]),
                'Minute': int(time_parts[1]) if len(time_parts) > 1 else 0
            }
        
        return None
    
    def remove_task(self, task_name):
        """Remove a scheduled task."""
        # Try to remove as launchd task
        if 'com.user.scheduled' in task_name:
            label = task_name
        else:
            label = f"com.user.scheduled.{task_name}"
        
        plist_path = self.launchd_user_path / f"{label}.plist"
        
        if plist_path.exists():
            # Unload the task
            subprocess.run(['launchctl', 'unload', str(plist_path)])
            # Remove the plist file
            plist_path.unlink()
            return f"Task '{task_name}' removed successfully"
        else:
            return f"Task '{task_name}' not found"
    
    def get_task_details(self, task_name):
        """Get detailed information about a specific task."""
        if 'com.user.scheduled' in task_name:
            label = task_name
        else:
            label = f"com.user.scheduled.{task_name}"
        
        plist_path = self.launchd_user_path / f"{label}.plist"
        
        if plist_path.exists():
            with open(plist_path, 'rb') as f:
                plist = plistlib.load(f)
            
            details = {
                'name': task_name,
                'label': label,
                'command': ' '.join(plist.get('ProgramArguments', [])),
                'run_at_load': plist.get('RunAtLoad', False),
                'stdout': plist.get('StandardOutPath', ''),
                'stderr': plist.get('StandardErrorPath', '')
            }
            
            if 'StartInterval' in plist:
                details['schedule'] = f"Every {plist['StartInterval']} seconds"
            elif 'StartCalendarInterval' in plist:
                cal = plist['StartCalendarInterval']
                details['schedule'] = self._format_calendar_interval(cal)
            
            return json.dumps(details, indent=2)
        else:
            return f"Task '{task_name}' not found"
    
    def _format_calendar_interval(self, cal):
        """Format calendar interval for display."""
        if isinstance(cal, list):
            cal = cal[0]
        
        parts = []
        if 'Weekday' in cal:
            weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 
                       'Thursday', 'Friday', 'Saturday']
            parts.append(f"Every {weekdays[cal['Weekday']]}")
        
        if 'Hour' in cal:
            hour = cal['Hour']
            minute = cal.get('Minute', 0)
            parts.append(f"at {hour:02d}:{minute:02d}")
        elif 'Minute' in cal:
            parts.append(f"at :{cal['Minute']:02d} every hour")
        
        return ' '.join(parts) if parts else 'Custom schedule'


def main():
    parser = argparse.ArgumentParser(description='macOS Task Scheduler Manager')
    subparsers = parser.add_subparsers(dest='command', help='Commands')
    
    # List command
    list_parser = subparsers.add_parser('list', help='List all scheduled tasks')
    list_parser.add_argument('--json', action='store_true', 
                            help='Output in JSON format')
    
    # Create command
    create_parser = subparsers.add_parser('create', help='Create a new task')
    create_parser.add_argument('name', help='Task name')
    create_parser.add_argument('command', help='Command to execute')
    create_parser.add_argument('--interval', type=int, 
                               help='Run every N seconds')
    create_parser.add_argument('--daily', help='Run daily at HH:MM')
    create_parser.add_argument('--hourly', help='Run hourly at :MM')
    create_parser.add_argument('--weekly', help='Run weekly on DAY@HH:MM')
    create_parser.add_argument('--startup', action='store_true',
                               help='Run at system startup')
    
    # Remove command
    remove_parser = subparsers.add_parser('remove', help='Remove a task')
    remove_parser.add_argument('name', help='Task name to remove')
    
    # Details command
    details_parser = subparsers.add_parser('details', help='Get task details')
    details_parser.add_argument('name', help='Task name')
    
    args = parser.parse_args()
    
    scheduler = MacOSScheduler()
    
    if args.command == 'list':
        format_out = 'json' if args.json else 'table'
        print(scheduler.list_tasks(format_out))
    
    elif args.command == 'create':
        if args.interval:
            result = scheduler.create_launchd_task(
                args.name, args.command, 'interval', args.interval)
        elif args.daily:
            result = scheduler.create_launchd_task(
                args.name, args.command, 'calendar', f'daily@{args.daily}')
        elif args.hourly:
            result = scheduler.create_launchd_task(
                args.name, args.command, 'calendar', f'hourly@{args.hourly}')
        elif args.weekly:
            result = scheduler.create_launchd_task(
                args.name, args.command, 'calendar', f'weekly@{args.weekly}')
        elif args.startup:
            result = scheduler.create_launchd_task(
                args.name, args.command, 'startup', None)
        else:
            print("Error: Must specify schedule type (--interval, --daily, etc.)")
            sys.exit(1)
        print(result)
    
    elif args.command == 'remove':
        print(scheduler.remove_task(args.name))
    
    elif args.command == 'details':
        print(scheduler.get_task_details(args.name))
    
    else:
        parser.print_help()


if __name__ == '__main__':
    main()
