#!/bin/bash

# PopPUNK Progress Monitor
# Helps monitor PopPUNK progress for large datasets

echo "PopPUNK Progress Monitor"
echo "======================="

# Find the most recent PopPUNK work directory
WORK_DIR=$(find work -name "*POPPUNK*" -type d | head -1)

if [ -z "$WORK_DIR" ]; then
    echo "No PopPUNK work directory found. Pipeline may not have started yet."
    exit 1
fi

echo "Monitoring PopPUNK in: $WORK_DIR"
echo ""

# Monitor function
monitor_progress() {
    while true; do
        if [ -f "$WORK_DIR/.command.log" ]; then
            echo "=== Latest Progress ==="
            tail -10 "$WORK_DIR/.command.log" | grep -E "(Progress|Creating|Fitting|Assigning|Found|Total)"
            echo ""
        fi
        
        # Check if process is still running
        if [ -f "$WORK_DIR/.exitcode" ]; then
            EXIT_CODE=$(cat "$WORK_DIR/.exitcode")
            if [ "$EXIT_CODE" -eq 0 ]; then
                echo "✅ PopPUNK completed successfully!"
                if [ -f "$WORK_DIR/clusters.csv" ]; then
                    CLUSTERS=$(tail -n +2 "$WORK_DIR/clusters.csv" | cut -f2 | sort -u | wc -l)
                    echo "Total clusters found: $CLUSTERS"
                fi
            else
                echo "❌ PopPUNK failed with exit code: $EXIT_CODE"
                echo "Check the error log:"
                tail -20 "$WORK_DIR/.command.err"
            fi
            break
        fi
        
        # Check memory usage
        if command -v free >/dev/null 2>&1; then
            echo "Memory usage:"
            free -h | head -2
            echo ""
        fi
        
        sleep 30
    done
}

# Start monitoring
echo "Starting monitoring (updates every 30 seconds)..."
echo "Press Ctrl+C to stop monitoring"
echo ""

monitor_progress