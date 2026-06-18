#!/bin/bash
if ! command -v b2 &> /dev/null; then
  echo "Installing B2 CLI..."
  pip3 install --quiet --user b2sdk b2
  export PATH="$HOME/.local/bin:$PATH"
fi
