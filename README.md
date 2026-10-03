# Self-Hosted Uncensored LLM

A reproducible setup for running a powerful **self-hosted, uncensored open-weight LLM** on your own GPU, with
a ChatGPT-style web UI and a public share link — no API keys, no per-token billing, no data leaving your box.

Built and tested on an **NVIDIA H200 (141 GB)** and an **RTX PRO 6000 Blackwell (96 GB)** via NVIDIA Brev.

## What you get

- **Ollama** serving open-weight models locally (GPU-accelerated)
- **Open WebUI** — a ChatGPT-style interface
- **Qwen2.5-72B-Instruct (abliterated)** — a 72B generalist with refusal behavior removed
- **Qwen2.5-Coder-32B (abliterated)** — an uncensored coding model that matches/beats GPT-4o on many
  coding benchmarks, and (unlike filtered coders) won't refuse legitimate security/offensive code
- A **public URL** via a Cloudflare quick tunnel (no account needed), so you can use it from any browser or phone
- One idempotent script — `bash setup.sh` — that brings the whole stack up

> "Abliterated" / "uncensored" means the model's built-in refusal behavior has been removed at the weights
> level, so it will engage with material that safety-tuned hosted assistants refuse. See **Responsible use**.

## Requirements

- A Linux host with an NVIDIA GPU (48 GB+ VRAM recommended for a 72B at Q4)
- Docker + the NVIDIA Container Toolkit
- ~50 GB free disk for the model

## Quick start

```bash
git clone https://github.com/<you>/uncensored-llm.git
cd uncensored-llm
bash setup.sh
```

That starts Ollama + Open WebUI, pulls the model (one-time), and prints a public `trycloudflare.com` URL.
Open it, pick the model in the top-left dropdown, and chat.

Use a different model:

```bash
MODEL=hf.co/<repo>/<model-gguf>:Q4_K_M bash setup.sh
```

## How it fits in VRAM

The 72B model is pulled as a **`Q4_K_M` GGUF** quant (~47 GB). Four-bit quantization is what lets a 72B model
run on a single GPU. On 96–141 GB cards you have ample headroom to run additional models alongside it.

| Component | Detail |
|---|---|
| Inference | Ollama |
| UI | Open WebUI (port 8080) |
| Chat model | Qwen2.5-72B-Instruct abliterated · Q4_K_M · ~47 GB |
| Coding model | Qwen2.5-Coder-32B-Instruct abliterated · Q4_K_M · ~20 GB |
| Public access | Cloudflare quick tunnel |
| GPU tested | H200 (141 GB), RTX PRO 6000 Blackwell (96 GB) |

### Other uncensored models worth trying

```bash
# lighter / faster uncensored coder
MODEL="" CODER_MODEL=hf.co/mradermacher/Qwen2.5-Coder-14B-Instruct-abliterated-GGUF:Q4_K_M bash setup.sh
# Dolphin (refusal-free, available directly on Ollama)
docker exec ollama ollama pull dolphin-mixtral:8x7b
```

## Files

- `docker-compose.yml` — Ollama + Open WebUI with GPU passthrough
- `setup.sh` — one-command bring-up: compose up → pull model → public tunnel
- `Uncensored-LLM-H200-Brief.md` — a short write-up of the build and the lessons

## Notes

- `WEBUI_AUTH=False` in the compose file means no login is required — convenient for a personal instance.
  Set it to `True` to require signup before the UI is usable.
- The Cloudflare quick-tunnel URL is unguessable but public while it is up; stop the tunnel when you are done.
- Models persist in the `ollama-models` Docker volume across restarts.

## Responsible use

This is for lawful, authorized use only. An uncensored model will produce content a filtered one won't — that
capability is for legitimate research, security testing you are authorized to perform, and private use. You are
responsible for complying with all applicable laws and the terms of the underlying model weights. Do not use it
to harm others or to produce illegal content.
