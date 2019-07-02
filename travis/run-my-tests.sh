#!/bin/bash

HOMEWORK_RUN=./travis/tests/run.sh

BRANCH=${TRAVIS_PULL_REQUEST_BRANCH:-$TRAVIS_BRANCH}

if [ "$BRANCH" == "" ]; then
  echo "We don't have tests for master branch"
  exit 0
fi

if [ -f $HOMEWORK_RUN ]; then
  echo "Run tests (my own linters, validators and so on)"
  # Docker container already started
  docker exec -e USER=appuser hw-test $HOMEWORK_RUN
else
  echo "We don't have tests... May be it is error??"
  exit 0
fi
