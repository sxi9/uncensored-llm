#!/usr/bin/env bash
# =====================================================================
#  Self-hosted uncensored LLM — one-command setup.
#  Brings up Ollama + Open WebUI (Docker), pulls an uncensored model,
#  and exposes the UI with a public URL via a Cloudflare quick tunnel.
#  Idempotent: safe to re-run.
#
#  Usage:   bash setup.sh
#  Model:   MODEL=<ollama-model> bash setup.sh   (override the default)
# =====================================================================
set -euo pipefail
cd "$(dirname "$0")"

# Models to pull (abliterated = refusal behavior removed = "uncensored").
#   MODEL       : general-purpose chat
#   CODER_MODEL : uncensored coding (matches/beats GPT-4o on many coding benchmarks)
# Override either from the environment, or set to "" to skip.
MODEL="${MODEL:-hf.co/mradermacher/Qwen2.5-72B-Instruct-abliterated-GGUF:Q4_K_M}"
CODER_MODEL="${CODER_MODEL:-hf.co/mradermacher/Qwen2.5-Coder-32B-Instruct-abliterated-GGUF:Q4_K_M}"

# ---------- 1. start Ollama + Open WebUI ----------
echo "[*] Starting containers..."
docker compose up -d

# ---------- 2. pull the models (only if missing) ----------
echo "[*] Waiting for Ollama to be ready..."
until docker exec ollama ollama list >/dev/null 2>&1; do sleep 2; done
pull_if_missing() {
  local m="$1"
  [ -z "$m" ] && return 0
  if docker exec ollama ollama list | grep -q "${m%%:*}"; then
    echo "[=] $m already present — skipping download"
  else
    echo "[*] Pulling $m (large, one-time)..."
    docker exec ollama ollama pull "$m"
  fi
}
pull_if_missing "$MODEL"
pull_if_missing "$CODER_MODEL"

# ---------- 3. public URL via Cloudflare quick tunnel ----------
if ! command -v cloudflared >/dev/null 2>&1 && [ ! -x ./cloudflared ]; then
  echo "[*] Downloading cloudflared..."
  curl -sL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o ./cloudflared
  chmod +x ./cloudflared
fi
CF="$(command -v cloudflared || echo ./cloudflared)"
pkill -f "cloudflared tunnel" 2>/dev/null || true
setsid "$CF" tunnel --url http://localhost:8080 --no-autoupdate > cloudflared.log 2>&1 < /dev/null &
echo "[*] Opening public tunnel..."
for i in $(seq 1 25); do
  U=$(grep -oE "https://[a-z0-9-]+\.trycloudflare\.com" cloudflared.log | head -1)
  if [ -n "$U" ]; then PUBLIC="$U"; break; fi
  sleep 3
done

echo ""
echo "============================================================"
echo "  Open WebUI (local):  http://localhost:8080"
[ -n "${PUBLIC:-}" ] && echo "  Open WebUI (public): $PUBLIC" \
                      || echo "  Public tunnel: see cloudflared.log"
echo "  Model loaded: $MODEL"
echo "============================================================"
echo "[+] Done. Pick the model in the top-left dropdown and chat."
