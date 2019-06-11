#!/bin/bash

# Install ruby
sudo apt update
sudo apt install -y ruby-full ruby-bundler build-essential git

# and check after install
ruby -v
bundler -v
