#!/bin/bash
set -eu

gcloud compute instances create reddit-app \
  --image-family reddit-full \
  --tags puma-server \
  --restart-on-failure
