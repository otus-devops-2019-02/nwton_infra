#!/bin/bash

if [[ "$#" -eq 0  ]]; then
  echo "Run with parameter --list or --host <name>"
  exit 1
fi

show_opt=$1

case "$show_opt" in
    --list )
        # simple cat JSON file
        cat ./inventory.json
        ;;
    --host )
        # echo empty list if meta section in JSON don't exist
        echo '{ }'
        ;;
    *)
        echo 'Unknown option'
        exit 1
        ;;
esac
