#!/bin/bash

# Define Slack Webhook URL
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/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"

# Define bandwidth limit (4.7 TB in bytes)
LIMIT=5173967454720 # 4.7 TB in bytes

# Function to install ifconfig if not installed
install_ifconfig() {
  if ! command -v ifconfig &> /dev/null; then
    echo "ifconfig is not installed. Installing..."
    sudo apt-get update
    sudo apt-get install net-tools -y
  fi
}

# Function to get the public IPv4 address using curl
get_ip_address() {
  IPV4_ADDRESS=$(curl -s http://checkip.amazonaws.com)
  echo $IPV4_ADDRESS
}

# Function to get the bandwidth usage from the eth0 interface
get_bandwidth_usage() {
  RX_BYTES=$(cat /sys/class/net/eth0/statistics/rx_bytes)
  TX_BYTES=$(cat /sys/class/net/eth0/statistics/tx_bytes)
  TOTAL_USAGE=$((RX_BYTES + TX_BYTES))
  echo $TOTAL_USAGE
}

# Function to send a message to Slack
send_slack_message() {
  local message=$1
  curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$message\"}" $SLACK_WEBHOOK_URL
}

# Function to check if script is added to cron and add if not
check_and_add_cron() {
  CRON_JOB="@every 30m /usr/local/bin/check_bandwidth.sh"
  
  # Check if cron job already exists
  if ! crontab -l | grep -F "$CRON_JOB" &> /dev/null; then
    # Add the cron job if it doesn't exist
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Cron job added to run every 30 minutes."
  else
    echo "Cron job already exists. Skipping."
  fi
}

# Main logic to check bandwidth usage
main() {
  # Install ifconfig if not installed
  install_ifconfig

  # Get current bandwidth usage
  CURRENT_USAGE=$(get_bandwidth_usage)

  # Check if bandwidth exceeds the limit (4.7 TB)
  if (( CURRENT_USAGE > LIMIT )); then
    # Get the public IPv4 address
    IP_ADDRESS=$(get_ip_address)

    # Get the current date and time
    DATE_TIME=$(date "+%Y-%m-%d %H:%M:%S")

    # Prepare message to send to Slack
    MESSAGE="Bandwidth limit exceeded!\nIPv4 Address: $IP_ADDRESS\nUsed Bandwidth: $((CURRENT_USAGE / 1024 / 1024 / 1024)) GB\nDate & Time: $DATE_TIME"

    # Send message to Slack
    send_slack_message "$MESSAGE"

    # Send shutdown message to Slack
    send_slack_message "Shutting down the system due to excessive bandwidth usage..."

    # Shutdown the system
    sudo shutdown -h now
  fi

  # Add this script to cron to run every 30 minutes if not already added
  check_and_add_cron
}

# Run the main function
main
