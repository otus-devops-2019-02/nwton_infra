#!/bin/bash

# Install ruby
sudo apt-get update
sudo apt-get install -y ruby-full ruby-bundler build-essential

# and check after install
ruby -v
bundler -v
