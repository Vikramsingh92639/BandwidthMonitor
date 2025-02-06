#!/bin/bash

# Check if ifconfig is installed
if ! command -v ifconfig &> /dev/null; then
    echo "ifconfig not found, installing net-tools..."
    sudo apt update && sudo apt install -y net-tools
else
    echo "ifconfig is already installed."
fi

# Get the IPv4 address of the VPS
ipv4_address=$(hostname -I | awk '{print $1}')

# Get the download and upload usage for eth0
eth0_stats=$(ifconfig eth0 | grep "RX bytes" | awk '{print $2, $6}' | sed 's/bytes://')
RX_bytes=$(echo $eth0_stats | awk '{print $1}')
TX_bytes=$(echo $eth0_stats | awk '{print $2}')

# Convert bytes to Terabytes for comparison
RX_TB=$(echo "scale=4; $RX_bytes/1024/1024/1024/1024" | bc)
TX_TB=$(echo "scale=4; $TX_bytes/1024/1024/1024/1024" | bc)

# Check if the bandwidth usage exceeds 4.7 TB (limit)
LIMIT=4.7

if (( $(echo "$RX_TB > $LIMIT" | bc -l) )) || (( $(echo "$TX_TB > $LIMIT" | bc -l) )); then
    # Send message to Slack webhook
    SLACK_WEBHOOK="https://hooks.slack.com/services/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"
    MESSAGE="Bandwidth limit exceeded on VPS with IP: $ipv4_address. RX: $RX_TB TB, TX: $TX_TB TB. Shutting down VPS."

    curl -X POST -H 'Content-type: application/json' --data "{
        \"text\": \"$MESSAGE\"
    }" $SLACK_WEBHOOK

    # Shutdown VPS
    sudo shutdown now
else
    echo "Bandwidth usage is within limits. RX: $RX_TB TB, TX: $TX_TB TB."
fi
 