#!/bin/bash

TOPIC_ARN="arn:aws:sns:us-east-1:123456789012:mission-control-alerts"

while true; do
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    memory_info=$(free | grep Mem)
    total_memory=$(echo $memory_info | awk '{print $2}')
    used_memory=$(echo $memory_info | awk '{print $3}')
    memory_usage=$(awk "BEGIN {print ($used_memory/$total_memory) * 100}")
    disk_usage=$(df -h / | awk '/\// {print $(NF-1)}' | sed 's/%//g')

    aws cloudwatch put-metric-data \
        --namespace "MissionControl" \
        --metric-data \
        "[
            {
                \"MetricName\": \"CPUUsage\",
                \"Value\": $cpu_usage,
                \"Unit\": \"Percent\"
            },
            {
                \"MetricName\": \"MemoryUsage\",
                \"Value\": $memory_usage,
                \"Unit\": \"Percent\"
            },
            {
                \"MetricName\": \"DiskUsage\",
                \"Value\": $disk_usage,
                \"Unit\": \"Percent\"
            }
        ]"

    if (( $(echo "$cpu_usage > 80" | bc -l) )) || 
       (( $(echo "$memory_usage > 80" | bc -l) )) || 
       (( $(echo "$disk_usage > 80" | bc -l) )); then
        aws sns publish \
            --topic-arn $TOPIC_ARN \
            --message "Alert: High resource usage detected. CPU: $cpu_usage%, Memory: $memory_usage%, Disk: $disk_usage%"
    fi

    sleep 60
done
