#!/bin/bash

# Ensure the script runs as root
if [ "$(id -u)" -ne "0" ]; then
  echo "This script must be run as root (use sudo)."
  exit 1
fi

# Variables
SCRIPT_NAME="bandwidth_monitor.sh"
DEST_PATH="/usr/local/bin/$SCRIPT_NAME"
NETWORK_INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)

# Check if the network interface was detected
if [ -z "$NETWORK_INTERFACE" ]; then
  echo "No valid network interface found."
  exit 1
fi

# Create the bandwidth monitor script
cat << 'EOF' > "$DEST_PATH"
#!/bin/bash

# Fetch the current bandwidth usage using vnstat
vnstat -i "$NETWORK_INTERFACE" -tr 1 2 | tail -n 1 | awk '{print $1, $2, $3, $4, $5}'
EOF

# Install dependencies
echo "Installing dependencies..."
apt-get update
apt-get install -y vnstat jq curl git

# Initialize vnstat database
echo "Initializing vnstat database..."
vnstat -u -i "$NETWORK_INTERFACE"  # Initialize the correct network interface

# Enable and start the vnstat service
echo "Enabling and starting vnstat service..."
systemctl enable vnstat
systemctl start vnstat

# Make sure the script is executable
chmod +x "$DEST_PATH"

# Set up cron job to run the script every minute
echo "Setting up cron job..."
(crontab -l 2>/dev/null; echo "* * * * * $DEST_PATH") | crontab -

# Ensure the script runs at reboot
echo "Setting up reboot trigger..."
(crontab -l 2>/dev/null; echo "@reboot $DEST_PATH") | crontab -

# Clean up any unused cron jobs
echo "Cleaning up cron jobs..."
crontab -l | grep -v "$SCRIPT_NAME" | crontab -

echo "Setup completed successfully!"
