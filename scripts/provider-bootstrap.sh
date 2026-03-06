#!/usr/bin/env bash
set -euo pipefail

mkdir -p /data /data/workspace

# Vertex AI: 把 Railway secret 里的 JSON 写成真正的凭证文件
if [ -n "${GCP_SERVICE_ACCOUNT_JSON:-}" ]; then
  printf '%s' "${GCP_SERVICE_ACCOUNT_JSON}" > /data/gcp-sa.json
  chmod 600 /data/gcp-sa.json
  export GOOGLE_APPLICATION_CREDENTIALS=/data/gcp-sa.json
fi

# Google Cloud 基础环境
if [ -n "${GOOGLE_CLOUD_PROJECT:-}" ]; then
  export GOOGLE_CLOUD_PROJECT
fi

if [ -n "${GOOGLE_CLOUD_LOCATION:-}" ]; then
  export GOOGLE_CLOUD_LOCATION
fi

# Aiberm: 安装并启用插件
if [ -n "${AIBERM_API_KEY:-}" ]; then
  openclaw plugins install openclaw-aiberm || true
  openclaw plugins enable openclaw-aiberm || true
  openclaw gateway restart || true
fi

# 交回模板原本的启动逻辑
exec ./entrypoint.sh
