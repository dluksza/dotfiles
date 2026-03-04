#!/usr/bin/env python3
"""
Efficient datetime utility for getting current date and time.
Minimal dependencies, fast execution, flexible output.
"""

import sys
from datetime import datetime
import argparse

def get_datetime(format_type='both', custom_format=None):
    """
    Get current datetime with minimal overhead.
    
    Args:
        format_type: 'date', 'time', 'both', 'iso', 'unix', or 'custom'
        custom_format: Custom strftime format string
    
    Returns:
        Formatted datetime string
    """
    now = datetime.now()
    
    if custom_format:
        return now.strftime(custom_format)
    
    formats = {
        'date': '%Y-%m-%d',
        'time': '%H:%M:%S',
        'both': '%Y-%m-%d %H:%M:%S',
        'iso': now.isoformat(),
        'unix': str(int(now.timestamp())),
        'full': '%A, %B %d, %Y at %I:%M %p',
        'short': '%b %d, %Y',
        'day': '%A',
        'month': '%B',
        'year': '%Y'
    }
    
    if format_type in formats:
        if format_type in ['iso', 'unix']:
            return formats[format_type]
        return now.strftime(formats[format_type])
    
    return now.strftime(formats['both'])

def main():
    parser = argparse.ArgumentParser(description='Get current date and time')
    parser.add_argument(
        '--format', '-f',
        choices=['date', 'time', 'both', 'iso', 'unix', 'full', 'short', 'day', 'month', 'year'],
        default='both',
        help='Output format (default: both)'
    )
    parser.add_argument(
        '--custom', '-c',
        help='Custom strftime format (e.g., "%%Y-%%m-%%d %%H:%%M")'
    )
    parser.add_argument(
        '--timezone', '-t',
        help='Timezone (requires pytz, fallback to system time if unavailable)'
    )
    
    args = parser.parse_args()
    
    # Handle timezone if requested and pytz is available
    if args.timezone:
        try:
            import pytz
            from datetime import datetime
            tz = pytz.timezone(args.timezone)
            now = datetime.now(tz)
            if args.custom:
                print(now.strftime(args.custom))
            elif args.format == 'iso':
                print(now.isoformat())
            elif args.format == 'unix':
                print(int(now.timestamp()))
            else:
                formats = {
                    'date': '%Y-%m-%d',
                    'time': '%H:%M:%S %Z',
                    'both': '%Y-%m-%d %H:%M:%S %Z',
                    'full': '%A, %B %d, %Y at %I:%M %p %Z',
                    'short': '%b %d, %Y',
                    'day': '%A',
                    'month': '%B',
                    'year': '%Y'
                }
                print(now.strftime(formats.get(args.format, formats['both'])))
        except ImportError:
            print(f"Warning: pytz not available, using system timezone", file=sys.stderr)
            print(get_datetime(args.format, args.custom))
        except Exception as e:
            print(f"Error with timezone: {e}", file=sys.stderr)
            print(get_datetime(args.format, args.custom))
    else:
        print(get_datetime(args.format, args.custom))

if __name__ == '__main__':
    main()
