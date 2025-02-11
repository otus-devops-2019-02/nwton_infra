#!/bin/bash
set -eu

# Add keys and repo
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list

# Install mongo
apt-get update
apt-get install -y mongodb-org

# Enable service
systemctl enable mongod
