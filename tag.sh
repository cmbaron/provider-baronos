#!/bin/bash

if [[ $(git diff --stat) != '' ]]; then
  echo 'fatal: cannot create tag with committed changes.'
  exit 1
fi

git tag -a "v31.337.$(date +%y%m%d%H%M%S)" "$@"
