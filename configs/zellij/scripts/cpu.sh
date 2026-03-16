#!/bin/bash
cpu_count=$(/usr/sbin/sysctl -n hw.logicalcpu)
ps -A -o pcpu= | awk -v c="$cpu_count" '{s+=$1}END{printf "%.0f%%\n", s/c}'
