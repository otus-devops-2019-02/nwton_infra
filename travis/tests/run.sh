#!/bin/bash
set -e

# Create keys
touch ~/.ssh/appuser.pub ~/.ssh/appuser

# Install requirements
cd ansible && ansible-galaxy install -r environments/stage/requirements.yml && cd ..

# Run InSpec
inspec exec travis/tests
