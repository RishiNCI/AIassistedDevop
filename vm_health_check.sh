#!/usr/bin/env bash
set -euo pipefail

EXPLAIN=false
if [[ "${1:-}" == "explain" ]]; then
  EXPLAIN=true
elif [[ $# -gt 0 ]]; then
  echo "Usage: $0 [explain]" >&2
  exit 1
fi

THRESHOLD=60

read -r cpu_idle1 cpu_total1 < <(awk '/^cpu / {idle=$5; total=0; for (i=2; i<=NF; i++) total+=$i; print idle, total}' /proc/stat)
sleep 1
read -r cpu_idle2 cpu_total2 < <(awk '/^cpu / {idle=$5; total=0; for (i=2; i<=NF; i++) total+=$i; print idle, total}' /proc/stat)

cpu_delta_total=$((cpu_total2 - cpu_total1))
cpu_delta_idle=$((cpu_idle2 - cpu_idle1))
if [[ $cpu_delta_total -le 0 ]]; then
  cpu_usage=0
else
  cpu_usage=$(( (100 * (cpu_delta_total - cpu_delta_idle)) / cpu_delta_total ))
fi

read -r mem_total mem_used < <(free -m | awk '/^Mem:/ {print $2, $3}')
if [[ $mem_total -le 0 ]]; then
  mem_usage=0
else
  mem_usage=$(( (100 * mem_used) / mem_total ))
fi

disk_usage=$(df -P / | awk 'NR==2 {gsub(/%/, "", $5); print $5}')

health_status="healthy"
reasons=()

if [[ $cpu_usage -ge $THRESHOLD ]]; then
  health_status="unhealthy"
  reasons+=("CPU utilization is ${cpu_usage}% (threshold: < ${THRESHOLD}%)")
fi

if [[ $mem_usage -ge $THRESHOLD ]]; then
  health_status="unhealthy"
  reasons+=("Memory utilization is ${mem_usage}% (threshold: < ${THRESHOLD}%)")
fi

if [[ $disk_usage -ge $THRESHOLD ]]; then
  health_status="unhealthy"
  reasons+=("Disk utilization is ${disk_usage}% (threshold: < ${THRESHOLD}%)")
fi

echo "$health_status"

if [[ "$EXPLAIN" == true ]]; then
  if [[ "$health_status" == "healthy" ]]; then
    echo "CPU utilization: ${cpu_usage}%"
    echo "Memory utilization: ${mem_usage}%"
    echo "Disk utilization: ${disk_usage}%"
    echo "All utilization values are below ${THRESHOLD}%."
  else
    printf '%s\n' "${reasons[@]}"
  fi
fi
