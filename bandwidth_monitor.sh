#!/bin/bash

# Define the Slack webhook URL
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/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"

# Define the shutdown threshold (4800 GB or 4.8 TB in GB)
THRESHOLD=4800  # GB

# Get current date
CURRENT_DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Get the IPv4 address of the VPS
IPV4_ADDRESS=$(curl -s http://checkip.amazonaws.com)

# Get current bandwidth usage (assuming vnstat is installed)
USED_BANDWIDTH=$(vnstat --json | jq '.interfaces[0].traffic.total.tx + .interfaces[0].traffic.total.rx' | awk '{print $1 / 1024 / 1024 / 1024}')  # Convert to GB

# Send updated bandwidth usage notification to Slack every 60 minutes
curl -X POST -H 'Content-type: application/json' --data "{
  \"text\": \"Bandwidth Usage Update\",
  \"attachments\": [
    {
      \"fields\": [
        {\"title\": \"IPv4 Address\", \"value\": \"$IPV4_ADDRESS\", \"short\": true},
        {\"title\": \"Bandwidth Used (GB)\", \"value\": \"$USED_BANDWIDTH GB\", \"short\": true},
        {\"title\": \"Date\", \"value\": \"$CURRENT_DATE\", \"short\": true}
      ]
    }
  ]
}" $SLACK_WEBHOOK_URL

# Check if the used bandwidth has reached the shutdown threshold (4.8 TB = 4800 GB)
if (( $(echo "$USED_BANDWIDTH >= $THRESHOLD" | bc -l) )); then
  # Send shutdown notification to Slack
  curl -X POST -H 'Content-type: application/json' --data "{
    \"text\": \"Bandwidth threshold reached! VPS is shutting down.\",
    \"attachments\": [
      {
        \"fields\": [
          {\"title\": \"IPv4 Address\", \"value\": \"$IPV4_ADDRESS\", \"short\": true},
          {\"title\": \"Bandwidth Used (GB)\", \"value\": \"$USED_BANDWIDTH GB\", \"short\": true},
          {\"title\": \"Date\", \"value\": \"$CURRENT_DATE\", \"short\": true}
        ]
      }
    ]
  }" $SLACK_WEBHOOK_URL

  # Shutdown the VPS
  shutdown -h now
fi
