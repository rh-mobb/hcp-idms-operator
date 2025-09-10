#!/bin/bash

# CRI-O Reload Monitor Script
# This script monitors for CRI-O reload signals and reloads CRI-O when needed

SIGNAL_FILE="/etc/containers/registry.conf.d/.crio-reload-needed"
LOG_FILE="/var/log/crio-reload-monitor.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

reload_crio() {
    log_message "CRI-O reload signal detected, attempting to reload CRI-O..."
    
    # Try systemctl reload first
    if systemctl reload crio 2>/dev/null; then
        log_message "Successfully reloaded CRI-O using systemctl reload"
        return 0
    fi
    
    # If reload fails, try sending SIGHUP
    if pkill -HUP crio 2>/dev/null; then
        log_message "Successfully sent SIGHUP to CRI-O"
        return 0
    fi
    
    # If SIGHUP fails, try restart
    if systemctl restart crio 2>/dev/null; then
        log_message "Successfully restarted CRI-O using systemctl restart"
        return 0
    fi
    
    log_message "ERROR: Failed to reload CRI-O using all methods"
    return 1
}

# Main monitoring loop
log_message "Starting CRI-O reload monitor..."

while true; do
    if [ -f "$SIGNAL_FILE" ]; then
        log_message "Signal file detected: $SIGNAL_FILE"
        
        # Read the signal file to get timestamp
        if [ -r "$SIGNAL_FILE" ]; then
            timestamp=$(grep "Generated at:" "$SIGNAL_FILE" | cut -d' ' -f3-4)
            log_message "Signal generated at: $timestamp"
        fi
        
        # Reload CRI-O
        if reload_crio; then
            # Remove the signal file after successful reload
            rm -f "$SIGNAL_FILE"
            log_message "Signal file removed after successful reload"
        else
            log_message "Keeping signal file due to reload failure"
        fi
    fi
    
    # Sleep for 5 seconds before checking again
    sleep 5
done
