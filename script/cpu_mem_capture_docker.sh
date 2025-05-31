#!/bin/bash

# === Argument validation ===
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <KEM> <DS>"
  exit 1
fi

KEM="$1"
DS="$2"

# === Container IDs ===
CLIENT_ID="06f4454f3e9b"
SERVER_ID="baee3e25377a"

# === Config ===
DURATION=2400  # Duration in seconds
OUTPUT_DIR="/opt/result/Multithread"
CSV_FILE="$OUTPUT_DIR/resource_usage_multi_thread.csv"

mkdir -p "$OUTPUT_DIR"

# === Initialize tracking ===
MAX_CPU_CLIENT=0
MAX_MEM_CLIENT=0
MAX_CPU_SERVER=0
MAX_MEM_SERVER=0

START=$(date +%s)
echo "Monitoring containers for $DURATION seconds..."

# === Monitoring loop ===
while (( $(date +%s) - START < DURATION )); do
  STATS=$(docker stats --no-stream --format "{{.Container}} {{.CPUPerc}} {{.MemPerc}}" "$CLIENT_ID" "$SERVER_ID" 2>/dev/null)

  while read -r CONTAINER CPU MEM; do
    CPU_VAL=$(echo "$CPU" | tr -d '%')
    MEM_VAL=$(echo "$MEM" | tr -d '%')

    if [[ "$CONTAINER" == "$CLIENT_ID" ]]; then
      (( $(echo "$CPU_VAL > $MAX_CPU_CLIENT" | bc -l) )) && MAX_CPU_CLIENT=$CPU_VAL
      (( $(echo "$MEM_VAL > $MAX_MEM_CLIENT" | bc -l) )) && MAX_MEM_CLIENT=$MEM_VAL
    elif [[ "$CONTAINER" == "$SERVER_ID" ]]; then
      (( $(echo "$CPU_VAL > $MAX_CPU_SERVER" | bc -l) )) && MAX_CPU_SERVER=$CPU_VAL
      (( $(echo "$MEM_VAL > $MAX_MEM_SERVER" | bc -l) )) && MAX_MEM_SERVER=$MEM_VAL
    fi
  done <<< "$STATS"
done

# === Write to CSV ===
if [ ! -f "$CSV_FILE" ]; then
  echo "KEM,DS,Client_CPU%,Client_MEM%,Server_CPU%,Server_MEM%" > "$CSV_FILE"
fi

echo "$KEM,$DS,$MAX_CPU_CLIENT,$MAX_MEM_CLIENT,$MAX_CPU_SERVER,$MAX_MEM_SERVER" >> "$CSV_FILE"

# === Print summary ===
echo ""
echo "=== Peak Resource Usage During ${DURATION}s ==="
echo "Client Container ($CLIENT_ID): Max CPU = $MAX_CPU_CLIENT%, Max MEM = $MAX_MEM_CLIENT%"
echo "Server Container ($SERVER_ID): Max CPU = $MAX_CPU_SERVER%, Max MEM = $MAX_MEM_SERVER%"
echo "Results saved to: $CSV_FILE"
