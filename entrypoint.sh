#!/bin/bash
set -e

STATE_DIR="${OPENCLAW_STATE_DIR:-/data/.openclaw}"
WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}"
CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$STATE_DIR/openclaw.json}"

export OPENCLAW_STATE_DIR="$STATE_DIR"
export OPENCLAW_WORKSPACE_DIR="$WORKSPACE_DIR"

# Ensure state/workspace paths exist and are writable
mkdir -p "$STATE_DIR/identity" "$WORKSPACE_DIR"
chown -R openclaw:openclaw /data 2>/dev/null || true
chmod 700 /data 2>/dev/null || true
chmod 700 "$STATE_DIR" 2>/dev/null || true
chmod 700 "$STATE_DIR/identity" 2>/dev/null || true

# Persist Homebrew to Railway volume so it survives container rebuilds
BREW_VOLUME="/data/.linuxbrew"
BREW_SYSTEM="/home/openclaw/.linuxbrew"

if [ -d "$BREW_VOLUME" ]; then
  if [ ! -L "$BREW_SYSTEM" ]; then
    rm -rf "$BREW_SYSTEM"
    ln -sf "$BREW_VOLUME" "$BREW_SYSTEM"
    echo "[entrypoint] Restored Homebrew from volume symlink"
  fi
else
  if [ -d "$BREW_SYSTEM" ] && [ ! -L "$BREW_SYSTEM" ]; then
    mv "$BREW_SYSTEM" "$BREW_VOLUME"
    ln -sf "$BREW_VOLUME" "$BREW_SYSTEM"
    echo "[entrypoint] Persisted Homebrew to volume on first boot"
  fi
fi

# Wire in Aiberm automatically when a config already exists
if [ -n "${AIBERM_API_KEY:-}" ] && [ -f "$CONFIG_PATH" ]; then
  echo "[entrypoint] AIBERM_API_KEY detected; enabling baked-in Aiberm provider"

  # Explicitly enable the bundled plugin
  gosu openclaw openclaw config set plugins.entries.openclaw-aiberm.enabled true --strict-json || true

  # Remove old allowlist so /model can see Aiberm models
  gosu openclaw openclaw config unset agents.defaults.models || true

  # Set default primary model
  gosu openclaw openclaw config set agents.defaults.model.primary "${AIBERM_DEFAULT_MODEL:-aiberm/anthropic/claude-sonnet-4.5}" || true

  # Optional single fallback model
  if [ -n "${AIBERM_FALLBACK_MODEL:-}" ]; then
    gosu openclaw openclaw config set agents.defaults.model.fallbacks "[\"${AIBERM_FALLBACK_MODEL}\"]" --strict-json || true
  fi
else
  echo "[entrypoint] Aiberm bootstrap skipped (missing AIBERM_API_KEY or config file)"
fi

exec gosu openclaw node src/server.js
