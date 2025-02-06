#!/bin/bash

# Ensure the script runs as root
if [ "$(id -u)" -ne "0" ]; then
  echo "This script must be run as root (use sudo)."
  exit 1
fi

# Variables
REPO_URL="https://github.com/Vikramsingh92639/BandwidthMonitor/blob/main/bandwidth_monitor.sh"
SCRIPT_NAME="bandwidth_monitor.sh" # Name of your script
DEST_PATH="/usr/local/bin/$SCRIPT_NAME" # Where the script will be saved

# Install dependencies
echo "Installing dependencies..."
apt-get update
apt-get install -y vnstat jq curl

# Initialize vnstat database
echo "Initializing vnstat database..."
vnstat -u -i eth0  # Change 'eth0' to your network interface name if needed.

# Enable and start the vnstat service
echo "Enabling and starting vnstat service..."
systemctl enable vnstat
systemctl start vnstat

# Clone the GitHub repository (assuming it's public)
echo "Cloning the repository from GitHub..."
git clone $REPO_URL /tmp/repo

# Copy the script to the destination path
echo "Copying the script to $DEST_PATH..."
cp /tmp/repo/$SCRIPT_NAME $DEST_PATH

# Make the script executable
chmod +x $DEST_PATH

# Set up cron job to run the script every minute
echo "Setting up cron job..."
(crontab -l 2>/dev/null; echo "* * * * * $DEST_PATH") | crontab -

# Ensure the script runs at reboot
echo "Setting up reboot trigger..."
(crontab -l 2>/dev/null; echo "@reboot $DEST_PATH") | crontab -

# Clean up temporary directory
rm -rf /tmp/repo

echo "Setup completed successfully!"
