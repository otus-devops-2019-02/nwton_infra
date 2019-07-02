#!/bin/bash
set -eu

# GIT must be installed before deploy
# sudo apt-get install -y git

# Install at home folder
cd ~

# Download and make
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install

# Make systemd unit
cat <<EOF > /etc/systemd/system/reddit-puma.service
[Unit]
Description=Simple reddit service
After=network.target

[Service]
User=appuser
Group=appuser
ExecStart=/usr/local/bin/puma
WorkingDirectory=/home/appuser/reddit
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

# Enable service
systemctl daemon-reload
systemctl enable reddit-puma
