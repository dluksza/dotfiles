#!/bin/bash
# Ultra-efficient datetime getter using built-in date command
# Usage: ./get_date.sh [format]
# Formats: date, time, both, iso, unix, full

FORMAT="${1:-both}"

case "$FORMAT" in
    date)
        date "+%Y-%m-%d"
        ;;
    time)
        date "+%H:%M:%S"
        ;;
    both)
        date "+%Y-%m-%d %H:%M:%S"
        ;;
    iso)
        date --iso-8601=seconds
        ;;
    unix)
        date "+%s"
        ;;
    full)
        date "+%A, %B %d, %Y at %I:%M %p"
        ;;
    day)
        date "+%A"
        ;;
    month)
        date "+%B"
        ;;
    year)
        date "+%Y"
        ;;
    *)
        # Custom format passed directly
        date "+$1"
        ;;
esac
