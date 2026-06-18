#!/bin/bash
if ! command -v b2 &> /dev/null; then
  echo "Installing B2 CLI..."
  B2_BIN="$HOME/.local/bin/b2"
  mkdir -p "$HOME/.local/bin"
  curl -fsSL "https://github.com/Backblaze/B2_Command_Line_Tool/releases/latest/download/b2-linux" \
    -o "$B2_BIN"
  chmod +x "$B2_BIN"
  export PATH="$HOME/.local/bin:$PATH"
fi
