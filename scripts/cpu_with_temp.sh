#!/bin/bash

# Get CPU usage (rounded to integer)
cpu_usage=$(top -bn1 | awk '/Cpu\(s\)/ {print $2}' | sed 's/%us,//' | awk '{printf "%.0f", $1}')

# Get CPU temperature - try multiple hwmon paths for different hardware
# AMD CPUs typically use k10temp (hwmon4 on this system)
temp_raw=""
for hwmon_path in /sys/class/hwmon/hwmon{0..9}; do
    if [ -f "$hwmon_path/name" ]; then
        sensor_name=$(cat "$hwmon_path/name" 2>/dev/null)
        # Check for CPU temperature sensors: k10temp (AMD), coretemp (Intel), zenpower
        if [[ "$sensor_name" =~ ^(k10temp|coretemp|zenpower)$ ]]; then
            temp_raw=$(cat "$hwmon_path/temp1_input" 2>/dev/null)
            if [ -n "$temp_raw" ]; then
                break
            fi
        fi
    fi
done

if [ -n "$temp_raw" ]; then
    temp_celsius=$((temp_raw / 1000))
    temp_line="CPU Temperature: ${temp_celsius}°C"
else
    temp_line="CPU Temperature: N/A"
fi

# Get CPU-consuming processes: always top 3, plus any others >=10% raw usage (limit first 12 entries)
top_procs=$(ps -eo comm,%cpu --sort=-%cpu --no-headers | head -n 12 |
    awk -v total="$cpu_usage" -v minCount=3 -v threshold=10 '
        {
            idx = NR;
            names[idx]=$1;
            raw[idx]=$2+0;
            count=idx;
        }
        END {
            if (count == 0) exit;

            for (i = 1; i <= count; i++) {
                if (i <= minCount || raw[i] >= threshold) {
                    include[i]=1;
                    sel_sum += raw[i];
                    sel_count++;
                }
            }

            if (sel_count == 0) exit;

            if (sel_sum <= 0 || total <= 0) {
                for (i = 1; i <= count; i++) if (include[i])
                    printf "%s: %.1f%%<br/>", names[i], raw[i];
            } else {
                for (i = 1; i <= count; i++) if (include[i]) {
                    adj = raw[i] * total / sel_sum;
                    if (adj < 0) adj = 0;
                    printf "%s: %.1f%%<br/>", names[i], adj;
                }
            }
        }
    ')

# Output JSON format: temperature above delimiter, CPU% + processes below
echo "{\"text\":\"  ${cpu_usage}%\",\"tooltip\":\"${temp_line}<hr/>CPU: ${cpu_usage}%<br/>${top_procs}\"}"
