# Phase 1: Environment - Research

**Researched:** 2026-03-25
**Domain:** Python conda environment setup, pretrained model weight acquisition, environment verification
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ENV-01 | 开发者可通过文档一步重建 `evo-rl` conda 环境（Python 3.10, 所有依赖） | Conda env exists at `/home/wzt/.conda/envs/evo-rl`; `requirements-ubuntu.txt` pinned lock file found; version drift detected (3 packages) |
| ENV-02 | 开发者可通过脚本/文档下载全部预训练权重（pi05_base、siglip-so400m-patch14-384、gemma-3-270m） | HuggingFace IDs confirmed: `lerobot/pi05_base`, `google/siglip-so400m-patch14-384`, `google/gemma-3-270m`; paligemma tokenizer already in `pretrained/paligemma-3b-pt-224`; the 3 main weights are MISSING |
| ENV-03 | 环境验证命令可在 10 秒内确认 CUDA、依赖、权重均就绪 | CUDA available (RTX 4090, 24GB); verification pattern already in `smoke_test_4090.sh`; needs a standalone fast-verify script |
</phase_requirements>

---

## Summary

Phase 1 establishes the reproducible developer environment for the Evo-RL project. The conda environment `evo-rl` already exists on the current machine at `/home/wzt/.conda/envs/evo-rl` with Python 3.10 and `lerobot 0.4.4` installed. The core deep learning stack (PyTorch 2.7.1, CUDA 12.6) is working and CUDA is available on the RTX 4090. However, three specific version drifts exist between the running environment and the pinned `requirements-ubuntu.txt`: `transformers` (installed 4.53.3, pinned 4.57.1), `wandb` (installed 0.24.2, pinned 0.21.4), and `accelerate` (installed 1.13.0, pinned 1.11.0).

The three pretrained weight directories required by the training scripts are absent: `pretrained/pi05_base` (~14GB, HF: `lerobot/pi05_base`), `pretrained/siglip-so400m-patch14-384` (HF: `google/siglip-so400m-patch14-384`), and `pretrained/gemma-3-270m` (HF: `google/gemma-3-270m`). Only the paligemma tokenizer files (`pretrained/paligemma-3b-pt-224/`) are already present. The dataset at `/home/wzt/wzt/data/pen` exists and has the correct LeRobot structure.

The deliverables for this phase are: (1) a setup document that lets a new developer recreate the env from scratch, (2) a `scripts/download_weights.sh` download script for the three missing weights, and (3) a `scripts/verify_env.sh` script that runs in under 10 seconds and confirms CUDA, all imports, and weight path availability.

**Primary recommendation:** Document the existing env exactly as-is (do not forcibly sync to `requirements-ubuntu.txt` pinned versions — the running env works), add a note about the version drift, write the download script for the three missing weights, and write a lightweight verification script.

---

## Standard Stack

### Core (already installed in evo-rl env)

| Library | Installed Version | Pinned (requirements-ubuntu.txt) | Purpose |
|---------|-------------------|----------------------------------|---------|
| Python | 3.10.19 | 3.10 | Base runtime |
| torch | 2.7.1+cu126 | 2.7.1 | DL training |
| torchvision | 0.22.1 | 0.22.1 | Vision utilities |
| transformers | 4.53.3 | **4.57.1** (drift) | Pretrained models |
| accelerate | 1.13.0 | **1.11.0** (drift) | Multi-GPU training |
| wandb | 0.24.2 | **0.21.4** (drift) | Experiment tracking |
| datasets | 4.1.1 | 4.1.1 | HF dataset loader |
| huggingface-hub | 0.35.3 | 0.35.3 | Model/dataset hub |
| lerobot | 0.4.4 | 0.4.4 | Robotics framework |

**Version drift note:** Three packages differ from pinned lockfile. The environment as installed has functioned in testing (all imports pass). The plan should document this drift but NOT automatically downgrade — only pin if tests reveal a concrete breakage.

### Pretrained Weights Required

| Model | HF ID | Local Path | Size (approx) | Status |
|-------|-------|------------|----------------|--------|
| pi05_base | `lerobot/pi05_base` | `Evo-RL/pretrained/pi05_base` | ~14GB | **MISSING** |
| siglip-so400m-patch14-384 | `google/siglip-so400m-patch14-384` | `Evo-RL/pretrained/siglip-so400m-patch14-384` | ~1.1GB | **MISSING** |
| gemma-3-270m | `google/gemma-3-270m` | `Evo-RL/pretrained/gemma-3-270m` | ~0.5GB | **MISSING** |
| paligemma-3b-pt-224 | `google/paligemma-3b-pt-224` | `Evo-RL/pretrained/paligemma-3b-pt-224/` | tokenizer only | Present (tokenizer files only) |

**Download commands (confirmed from `docs/huawei_npu_training_plan.md` and training scripts):**

```bash
# From Evo-RL/ directory with evo-rl conda env active
PRETRAINED_DIR="$(pwd)/pretrained"

huggingface-cli download lerobot/pi05_base \
    --local-dir "${PRETRAINED_DIR}/pi05_base"

huggingface-cli download google/siglip-so400m-patch14-384 \
    --local-dir "${PRETRAINED_DIR}/siglip-so400m-patch14-384"

huggingface-cli download google/gemma-3-270m \
    --local-dir "${PRETRAINED_DIR}/gemma-3-270m"
```

**Post-download step (critical):** `pi05_base/policy_preprocessor.json` defaults to `google/paligemma-3b-pt-224` for the tokenizer. On machines without HF access, update it to point to the local `pretrained/paligemma-3b-pt-224` path. On this machine (with HF access), this is a non-issue.

---

## Architecture Patterns

### Env Setup Pattern (conda + pip editable)

```bash
# Canonical install sequence
conda create -y -n evo-rl python=3.10
conda activate evo-rl
cd Evo-RL
pip install -e .
# Optionally install locked deps for full reproducibility:
# pip install -r requirements-ubuntu.txt
```

### Weight Storage Convention

```
Evo-RL/
└── pretrained/
    ├── pi05_base/            # lerobot/pi05_base (~14GB)
    ├── siglip-so400m-patch14-384/  # google/siglip-so400m-patch14-384
    ├── gemma-3-270m/         # google/gemma-3-270m
    └── paligemma-3b-pt-224/  # google/paligemma-3b-pt-224 tokenizer (already present)
```

Training scripts reference `${WORK_DIR}/pretrained` (set to `Evo-RL/pretrained`) — this convention is fixed in all existing `.sh` scripts.

### Verification Script Pattern

The existing `scripts/smoke_test_4090.sh` contains a fast CUDA check pattern (lines 72–82). The ENV-03 requirement calls for a standalone verification that completes in <10 seconds — well within reach since it only needs to check imports and path existence without loading any model weights.

```python
# Pattern from existing scripts (< 1s)
import torch
assert torch.cuda.is_available(), "CUDA not available!"
n = torch.cuda.device_count()
print(f"CUDA OK: {n} GPU(s), GPU 0: {torch.cuda.get_device_name(0)}")
```

### Anti-Patterns to Avoid

- **Using `pip install -r requirements-ubuntu.txt` on an existing env without `--force-reinstall`**: will silently skip already-installed packages, leaving drift in place.
- **Hard-coding absolute paths to `~/.conda/envs/evo-rl`** in documentation: use `conda activate evo-rl` for portability.
- **Downloading weights to `~/.cache/huggingface/hub/`**: the project explicitly uses `Evo-RL/pretrained/` as the local weight root — all training scripts expect weights there, not in the HF cache.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Weight download | Custom wget/curl download script | `huggingface-cli download` | Handles partial downloads, auth, HF file structures, checksums |
| Import verification | Custom import checker | `python -c "import X; print(X.__version__)"` inline | Simple, direct, no extra deps |
| CUDA detection | Custom device probe | `torch.cuda.is_available()` + `torch.cuda.device_count()` | Already in existing smoke test pattern |

**Key insight:** All download and verification logic can be thin shell scripts wrapping existing CLI tools. No new Python code needed for ENV-01–03.

---

## Common Pitfalls

### Pitfall 1: HuggingFace Rate Limiting or Network Unavailability

**What goes wrong:** `huggingface-cli download` hangs or fails mid-download (especially for 14GB pi05_base).
**Why it happens:** Rate limits, flaky connections, or Chinese network restrictions on HF access.
**How to avoid:** Set `HF_ENDPOINT=https://hf-mirror.com` for mirror access if direct HF is unreachable. Use `--resume-download` flag (supported by huggingface-hub >= 0.20).
**Warning signs:** Download speed drops to zero; partial files in pretrained dir.

### Pitfall 2: Version Drift Between Requirements Lockfile and Running Env

**What goes wrong:** `requirements-ubuntu.txt` specifies `transformers==4.57.1` but `4.53.3` is installed. A future developer following the doc may get a different env than the current working one.
**Why it happens:** Package upgrades after initial lockfile was generated.
**How to avoid:** Document: the *current machine* runs the drift versions successfully. The doc should state the pinned versions but flag them as "not enforced". Only pin strictly if a regression is detected.
**Warning signs:** Import errors after `pip install -r requirements-ubuntu.txt`.

### Pitfall 3: pi05_base tokenizer path in policy_preprocessor.json

**What goes wrong:** After downloading `pi05_base`, training fails with `FileNotFoundError` because `policy_preprocessor.json` references `google/paligemma-3b-pt-224` via HF Hub. On offline machines this will fail.
**Why it happens:** pi05_base bundles a preprocessor config pointing to the HF repo ID, not a local path.
**How to avoid:** After download, check/patch `pi05_base/policy_preprocessor.json` to use `../paligemma-3b-pt-224` (local). The paligemma tokenizer files are already present at `Evo-RL/pretrained/paligemma-3b-pt-224/`.
**Warning signs:** Training fails at processor initialization with missing tokenizer files.

### Pitfall 4: `pretrained/` directory not created before download

**What goes wrong:** `huggingface-cli download --local-dir` fails if `pretrained/pi05_base` parent does not exist.
**Why it happens:** `huggingface-cli` does NOT auto-create parent directories in all versions.
**How to avoid:** `mkdir -p pretrained/pi05_base pretrained/siglip-so400m-patch14-384 pretrained/gemma-3-270m` before download commands.

### Pitfall 5: Verification command takes too long

**What goes wrong:** ENV-03 requires verification in <10 seconds. A script that imports the full pi05 model takes 30+ seconds.
**Why it happens:** Model loading (even metadata-only) is expensive.
**How to avoid:** Verification script must ONLY check: (1) CUDA via torch, (2) key package imports with `__version__`, (3) path existence checks with `os.path.isdir`. Do NOT instantiate any model.

---

## Code Examples

### Verification Script Pattern (< 10 seconds)

```python
#!/usr/bin/env python3
# Source: adapted from Evo-RL/scripts/smoke_test_4090.sh (lines 72-82)
import sys
import os
import time

t0 = time.time()

# 1. CUDA check
import torch
cuda_ok = torch.cuda.is_available()
gpu_name = torch.cuda.get_device_name(0) if cuda_ok else "N/A"
gpu_mem = torch.cuda.get_device_properties(0).total_memory / 1e9 if cuda_ok else 0

# 2. Key dependency versions
import transformers
import accelerate
import lerobot
import datasets

# 3. Weight path check
PRETRAINED = os.path.join(os.path.dirname(__file__), "..", "pretrained")
weights = {
    "pi05_base": os.path.join(PRETRAINED, "pi05_base"),
    "siglip-so400m-patch14-384": os.path.join(PRETRAINED, "siglip-so400m-patch14-384"),
    "gemma-3-270m": os.path.join(PRETRAINED, "gemma-3-270m"),
}

print(f"CUDA: {'OK' if cuda_ok else 'NOT AVAILABLE'} | {gpu_name} ({gpu_mem:.1f} GB)")
print(f"torch: {torch.__version__}")
print(f"transformers: {transformers.__version__}")
print(f"accelerate: {accelerate.__version__}")
print(f"lerobot: {lerobot.__version__}")

all_pass = cuda_ok
for name, path in weights.items():
    found = os.path.isdir(path)
    all_pass = all_pass and found
    print(f"  {name}: {'OK' if found else 'MISSING'} ({path})")

elapsed = time.time() - t0
print(f"\nElapsed: {elapsed:.1f}s")
print("STATUS: READY" if all_pass else "STATUS: NOT READY — fix issues above")
sys.exit(0 if all_pass else 1)
```

### Download Script Pattern

```bash
#!/bin/bash
# Source: pattern from docs/huawei_npu_training_plan.md (lines 125-131)
set -euo pipefail
WORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PRETRAINED_DIR="${WORK_DIR}/pretrained"
mkdir -p "${PRETRAINED_DIR}"

# Optional: use HF mirror for China network
# export HF_ENDPOINT=https://hf-mirror.com

echo "Downloading pi05_base (~14GB)..."
huggingface-cli download lerobot/pi05_base \
    --local-dir "${PRETRAINED_DIR}/pi05_base"

echo "Downloading siglip-so400m-patch14-384..."
huggingface-cli download google/siglip-so400m-patch14-384 \
    --local-dir "${PRETRAINED_DIR}/siglip-so400m-patch14-384"

echo "Downloading gemma-3-270m..."
huggingface-cli download google/gemma-3-270m \
    --local-dir "${PRETRAINED_DIR}/gemma-3-270m"

echo "All weights downloaded to ${PRETRAINED_DIR}/"
```

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| conda | ENV-01 env setup | Yes | 24.x | — |
| Python 3.10 | ENV-01 | Yes | 3.10.19 (in evo-rl) | — |
| NVIDIA RTX 4090 | ENV-03 CUDA check | Yes | 24564 MiB | — |
| CUDA 12.6 | ENV-03 | Yes | cu126 (torch reports) | — |
| `huggingface-cli` | ENV-02 weight download | Yes | huggingface-hub 0.35.3 | pip install huggingface-hub |
| HuggingFace network | ENV-02 | Available (verify) | — | Use `HF_ENDPOINT=https://hf-mirror.com` |
| pi05_base weights | ENV-02, TRAIN-01 | **MISSING** | — | Must download; no fallback |
| siglip-so400m-patch14-384 | ENV-02, TRAIN-01 | **MISSING** | — | Must download; no fallback |
| gemma-3-270m | ENV-02, TRAIN-01 | **MISSING** | — | Must download; no fallback |
| /home/wzt/wzt/data/pen | All training | Yes | info.json present | — |

**Missing dependencies with no fallback:**
- `pretrained/pi05_base` — required for policy training (pi05). Must be downloaded via `huggingface-cli download lerobot/pi05_base`.
- `pretrained/siglip-so400m-patch14-384` — required for value training (pistar06 vision encoder). Must be downloaded via `huggingface-cli download google/siglip-so400m-patch14-384`.
- `pretrained/gemma-3-270m` — required for value training (pistar06 language encoder). Must be downloaded via `huggingface-cli download google/gemma-3-270m`.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual pip install from README | Pinned `requirements-ubuntu.txt` lockfile | Exists already | Full reproducibility when used |
| Loading models from HF Hub at runtime | Local `pretrained/` directory | Convention in all existing .sh scripts | Offline support, deterministic |

**Existing in-project prior art:** `docs/huawei_npu_training_plan.md` and `docs/reproduction_guide.md` contain detailed weight download instructions for the Huawei NPU environment (different paths). This phase creates the local-machine equivalent.

---

## Open Questions

1. **HuggingFace network access on target machines**
   - What we know: Current machine appears to have network; HF mirror is documented as fallback.
   - What's unclear: A100 and NPU machines may be offline or behind firewall.
   - Recommendation: Download script should include `HF_ENDPOINT` env var as a commented option.

2. **transformers version drift compatibility**
   - What we know: `transformers 4.53.3` is installed; `4.57.1` is pinned; `pistar06` config imports work now.
   - What's unclear: Whether `lerobot-value-train` or `lerobot-train` will fail due to API differences between 4.53.3 and 4.57.1 in practice (not tested in this research).
   - Recommendation: Document drift; add a note to verify by running smoke test after weight download. Only enforce downgrade if smoke test fails.

3. **Size of pi05_base on disk**
   - What we know: `docs/huawei_npu_training_plan.md` states ~14GB. `model.safetensors` was referenced.
   - What's unclear: Whether there are additional shards or the full checkpoint structure.
   - Recommendation: The download script handles this automatically via `huggingface-cli`.

---

## Sources

### Primary (HIGH confidence)
- Direct file inspection: `Evo-RL/scripts/train_pen_4090.sh` — confirmed weight path conventions and download commands
- Direct file inspection: `Evo-RL/scripts/smoke_test_4090.sh` — confirmed CUDA verification pattern
- Direct file inspection: `Evo-RL/src/lerobot/values/pistar06/configuration_pistar06.py` — confirmed `vision_repo_id = "google/siglip-so400m-patch14-384"` and `language_repo_id = "google/gemma-3-270m"` as defaults
- Runtime probe: `conda run -n evo-rl python` — confirmed installed versions
- Runtime probe: `nvidia-smi` — confirmed RTX 4090 24GB available, CUDA working

### Secondary (MEDIUM confidence)
- `Evo-RL/docs/huawei_npu_training_plan.md` — download commands and `pi05_base` size (~14GB), tokenizer path patching pattern
- `Evo-RL/docs/reproduction_guide.md` — confirmed same 4 model assets needed: `lerobot/pi05_base`, `google/paligemma-3b-pt-224`, `google/siglip-so400m-patch14-384`, `google/gemma-3-270m`
- `Evo-RL/requirements-ubuntu.txt` — confirmed pinned versions

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — directly probed running environment
- Pretrained weight IDs: HIGH — confirmed from source code (`configuration_pistar06.py`) and training scripts
- Architecture patterns: HIGH — all conventions read from existing scripts
- Pitfalls: MEDIUM — tokenizer path pitfall confirmed from docs; network/mirror pitfall is common knowledge

**Research date:** 2026-03-25
**Valid until:** 2026-04-25 (stable environment, 30-day horizon)
