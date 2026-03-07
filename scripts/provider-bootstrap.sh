#!/usr/bin/env bash
set -e

if [ -n "${AIBERM_API_KEY:-}" ]; then
  openclaw plugins install openclaw-aiberm || true
  openclaw plugins enable openclaw-aiberm || true
  openclaw gateway restart || true
  openclaw models auth login --provider aiberm --set-default || true
fi
