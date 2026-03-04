---
name: datetime
description: Provides current date, time, and datetime information in various formats. Use when users ask for the current date/time, use temporal keywords like "now", "today", "current time", or when any task requires actual timestamps. Triggers include (1) Direct requests for date/time ("what's the date?", "what time is it?"), (2) Keywords like "now", "today", "current", "present time", (3) Tasks needing timestamps (logging, file naming with dates, scheduling), (4) Date calculations or comparisons with "today", (5) Any context where the actual current date/time is needed for accuracy.
---

# DateTime Skill

Efficient utilities for getting current date and time with minimal overhead and maximum flexibility.

## Quick Start

### Most Common Uses

```bash
# Get current date and time (default)
scripts/get_datetime.py

# Get date only
scripts/get_datetime.py -f date

# Get time only  
scripts/get_datetime.py -f time

# Get full readable format
scripts/get_datetime.py -f full
```

### Ultra-Fast Bash Alternative

For maximum efficiency (no Python overhead):

```bash
# Using bash script (faster for simple cases)
scripts/get_date.sh date    # 2025-11-02
scripts/get_date.sh time    # 19:15:30
scripts/get_date.sh both    # 2025-11-02 19:15:30
```

## Available Formats

Both scripts support these format options:

- `date` - Date only (YYYY-MM-DD)
- `time` - Time only (HH:MM:SS)
- `both` - Date and time (YYYY-MM-DD HH:MM:SS) [default]
- `iso` - ISO 8601 format
- `unix` - Unix timestamp (seconds since epoch)
- `full` - Human readable (Sunday, November 02, 2025 at 07:15 PM)
- `short` - Short date (Nov 02, 2025)
- `day` - Day name only (Sunday)
- `month` - Month name only (November)
- `year` - Year only (2025)

## Advanced Usage

### Custom Formats

Python script supports custom strftime formats:

```bash
# Custom format with Python
scripts/get_datetime.py --custom "%B %d, %Y"  # November 02, 2025
scripts/get_datetime.py -c "%Y%m%d_%H%M%S"    # 20251102_191530

# Custom format with Bash (pass format string directly)
scripts/get_date.sh "%Y-%m-%d at %H:%M"       # 2025-11-02 at 19:15
```

### Timezone Support

Python script can handle different timezones (requires pytz):

```bash
# Get time in specific timezone
scripts/get_datetime.py --timezone "America/New_York" -f both
scripts/get_datetime.py -t "Europe/London" -f time
scripts/get_datetime.py -t "Asia/Tokyo" -f full
```

## Integration Examples

### In Python Code

```python
# Import and use directly
import sys
sys.path.append('/path/to/skill/scripts')
from get_datetime import get_datetime

current_time = get_datetime('both')
today = get_datetime('date')
timestamp = get_datetime('unix')
```

### File Naming with Timestamps

```bash
# Create timestamped files
filename="backup_$(scripts/get_date.sh "%Y%m%d_%H%M%S").tar.gz"
echo "Report generated on $(scripts/get_datetime.py -f full)" > report.txt
```

### Logging

```bash
# Add timestamps to logs
echo "[$(scripts/get_date.sh both)] Process started" >> logfile.log
```

## Performance Notes

- **Bash script** (`get_date.sh`): ~5ms execution time, best for simple formats
- **Python script** (`get_datetime.py`): ~30ms execution time, more features and flexibility
- Both scripts use only standard library (no external dependencies for basic functionality)
- Python timezone support gracefully degrades if pytz is unavailable

## Usage Guidelines

1. **Use bash script when**: You need simple date/time formats with minimal overhead
2. **Use Python script when**: You need custom formats, timezone support, or programmatic integration
3. **Always use for**: Any task requiring actual current date/time (not example or placeholder dates)
4. **Token efficiency**: Both scripts are designed to be executed directly without needing to load code into context
