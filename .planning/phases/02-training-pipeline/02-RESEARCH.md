# Phase 2: A100 环境部署 + 训练流水线 - Research

**Researched:** 2026-03-25
**Domain:** Shell scripting, rsync over SSH, conda env bootstrap, multi-GPU accelerate launch
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** A100 连接命令：`ssh moganshan@180.184.148.169 -p 10322`
- **D-02:** 登录后切换账号：`su lai`（个人目录挂载点：`/moganshan/afs_a/lai`）
- **D-03:** 连接详情存储在 `Evo-RL/A100_login.txt`，**不写入任何脚本或规划文档**
- **D-04:** A100 共 8 张卡，本项目最多使用 **4 张**（其余供其他同事使用）
- **D-05:** CUDA_VISIBLE_DEVICES 设为 `0,1,2,3`（4 卡）
- **D-06:** accelerate launch --num_processes=4 --mixed_precision=bf16
- **D-07:** per-device batch size = 8
  - Value 训练 effective batch = 8 × 4 = **32**
  - Policy 训练 effective batch = 8 × 4 = **32**
- **D-08:** 源路径：本地 `Evo-RL/`（项目根）
- **D-09:** 目标路径：`/moganshan/afs_a/lai/Evo-RL/`（A100 共享存储）
- **D-10:** 排除项：`.git`，`outputs/`，`pretrained/`
- **D-11:** rsync 参数：`-avz --progress -e "ssh -p 10322"`
- **D-12:** 权重源路径：`/media/wzt/jzh/Evo-RL/pretrained/`（本地，已确认）
- **D-13:** 权重目标路径：`/moganshan/afs_a/lai/pretrained/`（A100 共享存储）
- **D-14:** 传输方式：rsync `-avz --progress -e "ssh -p 10322"`（支持断点续传）
- **D-15:** 本 Phase 不上传数据集（fold_cloth 和 Kai0 后续单独处理）
- **D-16:** train_pen_A100.sh 中 `DATA_DIR` 写为 `/moganshan/afs_a/lai/data/fold_cloth`（占位，数据上传后启用）
- **D-17:** 环境名：`evo-rl`，Python 3.10
- **D-18:** 安装方式：`cd /moganshan/afs_a/lai/Evo-RL && pip install -e .`（editable install）
- **D-19:** 不从本地打包迁移 conda env，直接在 A100 重新安装
- **D-20:** 版本漂移（transformers 4.53.3 vs 4.57.1 等）不强制同步，文档记录即可
- **D-21:** 若 `evo-rl` 环境已存在，setup 脚本跳过创建，直接进行 pip install
- **D-22:** 脚本命名：`Evo-RL/scripts/train_pen_A100.sh`
- **D-23:** 以 `train_pen_4090.sh` 为模板，修改以下字段：

  | 字段 | 4090 | A100 |
  |------|------|------|
  | `WORK_DIR` | 本地路径 | `/moganshan/afs_a/lai/Evo-RL` |
  | `DATA_DIR` | `/home/wzt/wzt/data/pen` | `/moganshan/afs_a/lai/data/fold_cloth` |
  | `PRETRAINED_DIR` | `${WORK_DIR}/pretrained` | `/moganshan/afs_a/lai/pretrained` |
  | `OUTPUT_DIR` | `${WORK_DIR}/outputs/pen_round1_4090` | `${WORK_DIR}/outputs/pen_round1_A100` |
  | `NUM_GPUS` | 2 | 4 |
  | `LAUNCH` | `CUDA_VISIBLE_DEVICES=0,1 ...` | `CUDA_VISIBLE_DEVICES=0,1,2,3 ...` |
  | `VALUE_TRAIN_BATCH` | 8 | 8（可选：16）|
  | `PI05_BATCH` | 8 | 8（可选：16）|
  | 注释标题 | "2x RTX 4090 (24GB)" | "4x A100 (80GB)" |

- **D-24:** 特征选择（相机排除、关节切片）与 4090 版本保持一致：
  - `EXCLUDE_CAMERAS='["observation.images.right_wrist_right"]'`
  - `STATE_SLICE="0:7"`, `ACTION_SLICE="0:7"`

### Claude's Discretion

- rsync 脚本是合并一个（含 code/weights/all 子命令）还是分两个文件
- setup_a100_env.sh 是否包含 smoke test（import torch; assert CUDA）
- 是否创建单独的 smoke_test_A100.sh（类似 smoke_test_4090.sh 的精简版）

### Deferred Ideas (OUT OF SCOPE)

- 数据集 rsync 到 A100（fold_cloth / Kai0 在 Phase 2 或 Phase 3 前处理）
- NPU 训练脚本完善（train_pen_npu.sh 已存在，后续按需补充）
- wandb API key 配置（训练时交互式配置）
- 多用户 conda 环境共享（仅当团队扩展时考虑）
- A100 上的 smoke_test_A100.sh（可选，Claude 自行决定是否创建）
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TRAIN-01 | pen Round 1 可在单卡 RTX 4090 上完整运行 | Already met by train_pen_4090.sh (existing) |
| TRAIN-02 | pen Round 1 可在多卡 A100 上完整运行 | A100 script is a path/GPU adaptation of 4090 script; all CLI args verified from source |
| TRAIN-03 | pen Round 1 可在华为 NPU（8 卡）上完整运行 | train_pen_npu.sh already exists; out of scope for this phase |
| TRAIN-04 | 三套训练脚本（4090.sh / A100.sh / npu.sh）独立维护，batch size 和 GPU 配置按硬件适配 | A100.sh is new; 4090.sh and npu.sh already exist |
</phase_requirements>

---

## Summary

Phase 2 delivers four new scripts by adapting the already-verified `train_pen_4090.sh` template to A100 hardware. The research task is documentation extraction, not exploration: all three training stages (lerobot-value-train, lerobot-value-infer, lerobot-train) are already implemented and verified; this phase wraps them for the A100 GPU cluster.

The core engineering work is: (1) two rsync scripts for code and weights transfer over SSH port 10322, (2) a conda env bootstrap script that runs remotely via SSH, and (3) a 4-card A100 training script that differs from the 4090 version only in paths, GPU count, and CUDA_VISIBLE_DEVICES. The deferred 01-01-PLAN.md contains a complete rsync_to_a100.sh spec — that spec can be directly used as the implementation blueprint for Task 1.

The critical discovery is that the A100 environment setup (section 4.3 of reproduction_guide.md) documents the NPU (`.venv`) path, NOT the A100 CUDA path. The A100 setup must follow the local CUDA pattern: `conda create -n evo-rl python=3.10 && pip install -e . && pip install -e ".[pi]"`. The reproduction_guide.md's remote section describes NPU setup — do not use those exact commands for A100.

**Primary recommendation:** Write all four scripts in one plan wave; each script is a standalone deliverable with no cross-dependencies.

---

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| rsync | system | Code/weight transfer over SSH with resume support | Standard POSIX tool, handles 18GB weight transfer with `--partial` capability |
| ssh | system | Tunnel for rsync, -p 10322 | A100 is behind non-standard port |
| conda | system on A100 | Environment creation | Project standard (D-17, D-19) |
| pip | bundled with conda | Package install | `pip install -e .` is the install method (D-18) |
| accelerate | >=1.10.0,<2.0.0 | Multi-GPU DDP launch | Project standard; CUDA variant (not NPU) |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| bash `set -euo pipefail` | - | Fail-fast script execution | All scripts in this project use it |
| `$(which lerobot-value-train)` pattern | - | Resolve entrypoint from conda env | Used in 4090.sh and smoke_test_4090.sh; preserves on A100 |
| `eval ${LAUNCH}` pattern | - | Execute variable-stored launch command | Used in 4090.sh; preserves on A100 |
| `nohup ... > log 2>&1 &` | - | Background training | A100 training runs for hours; background required |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Two separate rsync files | One file with subcommands (code/weights/all) | Single file is cleaner UX; deferred 01-01-PLAN.md already specifies the subcommand design |
| conda in setup script | venv --system-site-packages | NPU used venv; A100 is CUDA, conda is simpler and aligns with local env (D-17) |

**Installation (on A100, after code rsync):**
```bash
conda create -n evo-rl python=3.10 -y
conda activate evo-rl
cd /moganshan/afs_a/lai/Evo-RL
pip install -e .
pip install -e ".[pi]"
```

---

## Architecture Patterns

### Recommended Script Layout
```
Evo-RL/scripts/
├── rsync_to_a100.sh          # NEW: code + weights transfer (subcommand style)
├── rsync_weights_to_a100.sh  # NEW: weights-only transfer (D-12 → D-13)
├── setup_a100_env.sh         # NEW: conda env init on A100 via SSH
├── train_pen_A100.sh         # NEW: 4-card A100 training (D-22)
├── train_pen_4090.sh         # EXISTING: 2-card 4090 training (template)
├── smoke_test_4090.sh        # EXISTING: smoke test pattern to follow
└── train_pen_npu.sh          # EXISTING: NPU training (separate, not referenced)
```

### Pattern 1: rsync Transfer Script

**What:** rsync with `-avz --progress -e "ssh -p 10322"`, excludes `.git`, `outputs/`, `pretrained/`
**When to use:** Transferring code updates or initial weight push
**Key finding:** The deferred 01-01-PLAN.md already has a complete, reviewed spec for `rsync_to_a100.sh` with `code|weights|all` subcommands. The planner should reuse that spec verbatim.

```bash
# Source: .planning/phases/01-environment/01-01-PLAN.md.deferred (Task 2 action block)
A100_HOST="moganshan@180.184.148.169"
A100_PORT=10322
SSH_CMD="ssh -p ${A100_PORT}"

rsync -avz --progress \
    --exclude='.git' \
    --exclude='outputs/' \
    --exclude='pretrained/' \
    "${WORK_DIR}/" \
    "${A100_HOST}:${A100_CODE_DIR}/" \
    -e "${SSH_CMD}"
```

**CONTEXT.md D-11 note:** The reference command in `<specifics>` section places `-e "ssh -p 10322"` at the end of the rsync command. This is correct syntax. Use exactly as shown.

### Pattern 2: Weight-Only rsync

**What:** Transfer `/media/wzt/jzh/Evo-RL/pretrained/` to `/moganshan/afs_a/lai/pretrained/` (D-12 → D-13)
**Source path is NOT inside Evo-RL/:** It is on a separate disk `/media/wzt/jzh/Evo-RL/pretrained/`. The script cannot use `${WORK_DIR}/pretrained` for the source.

```bash
# Source: CONTEXT.md D-12/D-13 specifics block
LOCAL_PRETRAINED="/media/wzt/jzh/Evo-RL/pretrained/"
A100_PRETRAINED="/moganshan/afs_a/lai/pretrained/"

rsync -avz --progress \
    "${LOCAL_PRETRAINED}" \
    "moganshan@180.184.148.169:${A100_PRETRAINED}" \
    -e "ssh -p 10322"
```

### Pattern 3: conda env setup via SSH heredoc

**What:** Remote conda env creation piped via SSH
**When to use:** One-time A100 env initialization

```bash
# Executed from local machine, runs commands on A100
ssh moganshan@180.184.148.169 -p 10322 bash << 'REMOTE'
  su lai -c "
    conda create -n evo-rl python=3.10 -y || true
    conda activate evo-rl
    cd /moganshan/afs_a/lai/Evo-RL
    pip install -e .
    pip install -e '.[pi]'
  "
REMOTE
```

**Pitfall:** `su lai` inside SSH does not preserve conda PATH. The setup script should print step-by-step instructions for manual execution rather than attempting unattended `su` switching. Alternatively, use a script that is copied to A100 and run there.

**Recommended approach:** `setup_a100_env.sh` generates a companion `_remote_setup.sh` file and prints the SSH command to run it on A100. Or it simply documents the steps. The user must manually `su lai` after SSH login (D-02).

### Pattern 4: A100 Training Script (4-card CUDA)

**What:** Exact adaptation of train_pen_4090.sh with 5 field changes
**Template:** `Evo-RL/scripts/train_pen_4090.sh` — copy fully, then apply diff below

```bash
# Source: train_pen_4090.sh lines 61-76, modified per CONTEXT.md D-23
WORK_DIR="/moganshan/afs_a/lai/Evo-RL"    # hardcoded, not dynamic dirname
DATA_DIR="/moganshan/afs_a/lai/data/fold_cloth"
PRETRAINED_DIR="/moganshan/afs_a/lai/pretrained"
OUTPUT_DIR="${WORK_DIR}/outputs/pen_round1_A100"
NUM_GPUS=4
LAUNCH="CUDA_VISIBLE_DEVICES=0,1,2,3 accelerate launch --multi_gpu --num_processes=${NUM_GPUS} --mixed_precision=bf16"
```

All other content (step headers, LAUNCH eval pattern, CLI argument blocks, feature selection variables, pre-checks) is **preserved verbatim** from train_pen_4090.sh.

### Anti-Patterns to Avoid

- **Referencing train_pen_npu.sh:** It uses `ASCEND_RT_VISIBLE_DEVICES`, `.venv` activation, and Huawei-specific paths — entirely incompatible with NVIDIA CUDA A100.
- **Dynamic `WORK_DIR` on A100:** `WORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"` works fine locally, but CONTEXT.md D-23 explicitly notes A100 WORK_DIR is hardcoded as `/moganshan/afs_a/lai/Evo-RL`. Use the hardcoded path.
- **Storing passwords in scripts:** CONTEXT.md security constraint — all scripts must have zero credentials. SSH port only, no password.
- **Unattended `su lai` in SSH heredoc:** `su` requires interactive TTY. The setup script should provide manual instructions.
- **Using `pip install -e ".[pi]"` as the only install:** The `.[pi]` extra installs the custom transformers branch needed for PI0.5. The base `pip install -e .` installs core deps. Both are needed on A100.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-GPU launch coordination | Custom DDP setup | `accelerate launch --multi_gpu --num_processes=4` | Project already uses this; verified on 4090 |
| Checkpoint resume | Custom resume logic | `--steps` + existing `output_dir` checkpoint detection | Training scripts already handle resume |
| Weight download | Custom HF downloader | `huggingface-cli download` | Already in download_weights.sh (deferred plan) |
| Partial rsync resume | Manual retry loop | rsync native `--partial` / `-avz` | rsync handles partial transfers by design |

---

## Complete CLI Argument Reference

This section extracts every CLI argument from `train_pen_4090.sh` verbatim. The A100 script must preserve all of these.

### Stage 1: lerobot-value-train
```bash
eval ${LAUNCH} $(which lerobot-value-train) \
  --dataset.repo_id="${DATASET_REPO_ID}" \
  --dataset.root="${DATA_DIR}" \
  --value.type=pistar06 \
  --value.dtype=bfloat16 \
  --value.vision_repo_id="${PRETRAINED_DIR}/siglip-so400m-patch14-384" \
  --value.language_repo_id="${PRETRAINED_DIR}/gemma-3-270m" \
  --batch_size="${VALUE_TRAIN_BATCH}" \
  --steps="${VALUE_TRAIN_STEPS}" \
  --save_freq="${VALUE_SAVE_FREQ}" \
  ${EXCLUDE_CAMERAS:+--train_exclude_cameras="${EXCLUDE_CAMERAS}"} \
  ${STATE_SLICE:+--train_state_slice="${STATE_SLICE}"} \
  --output_dir="${OUTPUT_DIR}/value_train" \
  --job_name=pen_value_r1_A100
```

**A100 differences:** `job_name` suffix changes to `_A100`; paths updated per D-23.

### Stage 2: lerobot-value-infer
```bash
eval ${LAUNCH} $(which lerobot-value-infer) \
  --dataset.repo_id="${DATASET_REPO_ID}" \
  --dataset.root="${DATA_DIR}" \
  --inference.checkpoint_path="${OUTPUT_DIR}/value_train" \
  --runtime.batch_size=8 \
  --acp.enable=true \
  --acp.n_step=50 \
  --acp.positive_ratio=0.3 \
  --acp.value_field=complementary_info.value_r1 \
  --acp.advantage_field=complementary_info.advantage_r1 \
  --acp.indicator_field=complementary_info.acp_indicator_r1 \
  --output_dir="${OUTPUT_DIR}/value_infer" \
  --job_name=pen_infer_r1_A100
```

**Note:** `--runtime.batch_size=8` is hardcoded (not a variable) in the 4090 script. Preserve this on A100.

### Stage 3: lerobot-train (PI0.5)
```bash
eval ${LAUNCH} $(which lerobot-train) \
  --dataset.repo_id="${DATASET_REPO_ID}" \
  --dataset.root="${DATA_DIR}" \
  --policy.type=pi05 \
  --policy.pretrained_path="${PRETRAINED_DIR}/pi05_base" \
  --policy.push_to_hub=false \
  --policy.dtype=bfloat16 \
  --policy.gradient_checkpointing=true \
  --policy.train_expert_only=false \
  --batch_size="${PI05_BATCH}" \
  --steps="${PI05_TRAIN_STEPS}" \
  --num_workers=4 \
  --save_freq="${PI05_SAVE_FREQ}" \
  --log_freq="${PI05_LOG_FREQ}" \
  --acp.enable=true \
  --acp.indicator_field=complementary_info.acp_indicator_r1 \
  --acp.indicator_dropout_prob=0.3 \
  ${EXCLUDE_CAMERAS:+--train_exclude_cameras="${EXCLUDE_CAMERAS}"} \
  ${STATE_SLICE:+--train_state_slice="${STATE_SLICE}"} \
  ${ACTION_SLICE:+--train_action_slice="${ACTION_SLICE}"} \
  --output_dir="${OUTPUT_DIR}/pi05_train" \
  --job_name=pen_pi05_r1_A100
```

**A100 note:** `--policy.train_expert_only=false` (full param training) is correct for A100. A100 has 80GB per card vs 24GB for 4090 — no memory constraint forcing expert-only mode.

---

## Common Pitfalls

### Pitfall 1: Weights source path is NOT inside Evo-RL/
**What goes wrong:** rsync_weights script calculates source as `${WORK_DIR}/pretrained/` — this is the A100 destination, not the local source.
**Root cause:** The 18GB weights are on `/media/wzt/jzh/Evo-RL/pretrained/` (separate disk), not in the project directory.
**How to avoid:** `rsync_weights_to_a100.sh` must hardcode (or require as argument) the local source path `/media/wzt/jzh/Evo-RL/pretrained/`.
**From:** CONTEXT.md D-12 explicitly documents this path.

### Pitfall 2: `su lai` is not scriptable without TTY
**What goes wrong:** `ssh ... bash -c "su lai -c '...'"` fails silently — `su` requires interactive password input.
**Root cause:** Non-interactive SSH sessions cannot use `su` without PAM configuration changes.
**How to avoid:** `setup_a100_env.sh` should either:
  (a) Print SSH command + instructions for manual `su lai` execution, or
  (b) Copy a setup script to A100 with `rsync` first, then `ssh` into it with TTY (`ssh -t`) so user can type the `su lai` password interactively
**Warning signs:** Script hangs or exits immediately when SSH is run.

### Pitfall 3: torchcodec conflict on some environments
**What goes wrong:** `lerobot-value-infer` crashes with torchcodec-related error.
**Root cause:** Seen in `resume_cloth_round1_4090.sh` — torchcodec has compatibility issues on some CUDA environments.
**How to avoid:** Add a note in `setup_a100_env.sh` that if value-infer fails with torchcodec error: `pip uninstall torchcodec -y`. The `resume_cloth_round1_4090.sh` script already documents this workaround.
**Warning signs:** Error message mentioning `torchcodec` in lerobot-value-infer stage.

### Pitfall 4: conda activate inside non-interactive shell
**What goes wrong:** `conda activate evo-rl` fails with "conda init has not been run" in non-interactive bash scripts.
**Root cause:** `conda activate` requires conda shell hooks initialized by `conda init`.
**How to avoid:** In the setup script, use `source $(conda info --base)/etc/profile.d/conda.sh && conda activate evo-rl` OR simply instruct the user to manually activate. Background training scripts (train_pen_A100.sh) should document `conda activate evo-rl` in usage comments, not attempt it inside the script.

### Pitfall 5: DATASET_REPO_ID mismatch after `su lai`
**What goes wrong:** `DATASET_REPO_ID` is set to `wzt/pen` in the training script. If the dataset was uploaded to HF under a different account (e.g., `lai/pen` or the data is local-only), the repo_id lookup fails.
**Root cause:** `repo_id` is used for metadata and optional HF push; `dataset.root` is the actual data path.
**How to avoid:** With `DATA_DIR` pointing to a local path and `--policy.push_to_hub=false`, the repo_id is effectively just a label. Keep as `wzt/pen` in the A100 script (matches 4090 script). Document that this is a local-run identifier only.

### Pitfall 6: A100 pretrained path diverges from WORK_DIR
**What goes wrong:** On 4090, `PRETRAINED_DIR="${WORK_DIR}/pretrained"` is correct. On A100, pretrained weights are at `/moganshan/afs_a/lai/pretrained/` (separate from `WORK_DIR=/moganshan/afs_a/lai/Evo-RL`).
**Root cause:** CONTEXT.md D-13 puts weights OUTSIDE the Evo-RL dir on A100.
**How to avoid:** `PRETRAINED_DIR="/moganshan/afs_a/lai/pretrained"` (absolute, not relative to WORK_DIR).

---

## Code Examples

### rsync_to_a100.sh pattern (code sync)
```bash
# Source: CONTEXT.md <specifics> block, D-08 through D-11
rsync -avz --progress \
    --exclude='.git' \
    --exclude='outputs/' \
    --exclude='pretrained/' \
    /home/wzt/wzt/mycode/my_RL/Evo-RL/ \
    moganshan@180.184.148.169:/moganshan/afs_a/lai/Evo-RL/ \
    -e "ssh -p 10322"
```

### rsync_weights_to_a100.sh pattern
```bash
# Source: CONTEXT.md <specifics> block, D-12 through D-14
rsync -avz --progress \
    /media/wzt/jzh/Evo-RL/pretrained/ \
    moganshan@180.184.148.169:/moganshan/afs_a/lai/pretrained/ \
    -e "ssh -p 10322"
```

### setup_a100_env.sh: conda idempotency check (D-21)
```bash
# Source: CONTEXT.md D-21
if conda env list | grep -q "^evo-rl "; then
    echo "conda env 'evo-rl' already exists, skipping creation."
else
    conda create -n evo-rl python=3.10 -y
fi
```

### CUDA check in pre-flight (from train_pen_4090.sh lines 138-147)
```bash
# Source: Evo-RL/scripts/train_pen_4090.sh lines 138-147
python3 -c "
import torch
assert torch.cuda.is_available(), 'CUDA not available!'
n = torch.cuda.device_count()
print(f'CUDA OK: {n} GPU(s)')
for i in range(n):
    name = torch.cuda.get_device_name(i)
    mem = torch.cuda.get_device_properties(i).total_memory / 1e9
    print(f'  GPU {i}: {name} ({mem:.1f} GB)')
"
```

### smoke_test_A100.sh: single-pass no-fallback version
```bash
# Unlike smoke_test_4090.sh which tests batch=4 and batch=8 variants,
# A100 has sufficient memory. Use fixed batch=8, SMOKE_STEPS=10.
SMOKE_STEPS=10
NUM_GPUS=4
LAUNCH="CUDA_VISIBLE_DEVICES=0,1,2,3 accelerate launch --multi_gpu --num_processes=${NUM_GPUS} --mixed_precision=bf16"
```

---

## Environment Availability

> Step 2.6: Applicable — Phase depends on A100 remote connectivity and local rsync/ssh tools.

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| rsync | Code/weight transfer | ✓ | system (Linux) | — |
| ssh (port 10322) | A100 connection | Cannot verify locally | — | Check A100_login.txt |
| conda (on A100) | env creation | Cannot verify locally | — | Document manual steps |
| CUDA 4x A100 (on A100) | train_pen_A100.sh | Cannot verify locally | — | Script has pre-flight CUDA check |
| `.[pi]` extra (transformers custom branch) | PI0.5 training | Requires network/git on A100 | — | Must be installed during setup |

**Missing dependencies with no fallback:**
- A100 SSH access cannot be verified from local machine — execution of `setup_a100_env.sh` and `train_pen_A100.sh` requires human to confirm connectivity and `su lai` login.

**Missing dependencies with fallback:**
- If A100 conda unavailable: document `python -m venv .venv --system-site-packages` as NPU-style fallback (though conda is preferred per D-17).

---

## pyproject.toml: pip install extras for A100

The `.[pi]` optional extra is critical for A100 (as for any CUDA environment where PI0.5 is trained):

```toml
# From Evo-RL/pyproject.toml line 138
pi = ["transformers @ git+https://github.com/huggingface/transformers.git@fix/lerobot_openpi", "scipy>=1.10.1,<1.15"]
```

This installs a **custom transformers branch** (not PyPI). A100 must have internet access to GitHub at install time, OR the branch must be pre-cloned. The `transformers-dep` extra (`transformers>=4.57.1`) conflicts with `.[pi]` — do not install both.

Base install `pip install -e .` does NOT include transformers — it's only pulled via optionals. Setup script must run `pip install -e ".[pi]"` after base install.

---

## Script Decision: rsync_to_a100.sh vs separate files

**Recommendation (Claude's Discretion):** Create TWO separate files:
1. `rsync_to_a100.sh` — code-only sync (D-08 to D-11); uses `WORK_DIR` dynamic resolution
2. `rsync_weights_to_a100.sh` — weights-only sync (D-12 to D-14); hardcodes `/media/wzt/jzh/Evo-RL/pretrained/`

**Rationale:** The source paths are fundamentally different — code comes from project root (dynamic), weights come from a separate disk path (hardcoded). Merging into one file with subcommands requires the code sync function to hardcode the weights path or accept a parameter, which adds complexity. Keeping separate files matches the CONTEXT.md Phase Boundary listing (two distinct script names: `rsync_to_a100.sh` and `rsync_weights_to_a100.sh`).

---

## Script Decision: smoke_test_A100.sh

**Recommendation (Claude's Discretion):** CREATE `smoke_test_A100.sh`.

**Rationale:**
- The 4090 smoke test tests batch=4 and batch=8 variants because 24GB VRAM is a constraint — some batches may OOM. A100 has 80GB, so this concern is gone.
- A100 smoke test can be simpler: fixed batch=8, 10 steps, no fallback logic.
- It serves as the verification gate before running the full 30000-step training job.
- Pattern is already established by `smoke_test_4090.sh` — trivial to adapt.

---

## Script Decision: setup_a100_env.sh structure

**Recommendation (Claude's Discretion):** Design as a **local script that generates + copies + executes**:

1. Generates a `_a100_remote_env_setup.sh` helper (not committed to git)
2. Copies it to A100 via rsync
3. Prints the manual SSH command the user must run to execute it

The user still needs to SSH and `su lai` manually (cannot be scripted), but all conda/pip commands are encapsulated in the remote helper. This minimizes what the user must type after login.

---

## Open Questions

1. **Does A100 have internet access to GitHub for `.[pi]` install?**
   - What we know: `.[pi]` pulls `transformers @ git+https://github.com/...`
   - What's unclear: A100 network policy (firewall rules for outbound HTTPS to GitHub)
   - Recommendation: Setup script should include a note about this dependency and offer an alternative: pre-clone the transformers fork locally and rsync it, then install from local path.

2. **What is the A100 conda binary path?**
   - What we know: A100 runs under shared account `moganshan`, personal dir at `/moganshan/afs_a/lai`
   - What's unclear: Whether conda is in PATH for user `lai` after `su lai`
   - Recommendation: Setup script should include `which conda || echo "conda not in PATH"` check before create.

3. **DATASET_REPO_ID on A100 (`wzt/pen` vs local-only)**
   - What we know: `DATA_DIR` is local path; `push_to_hub=false` in policy train
   - What's unclear: Whether lerobot-value-train or lerobot-value-infer attempts any HF hub operations with `repo_id`
   - Recommendation: Keep `wzt/pen` as repo_id (matches 4090.sh); it's used as metadata/job_name only when hub push is disabled.

---

## Sources

### Primary (HIGH confidence)
- `Evo-RL/scripts/train_pen_4090.sh` — complete 3-stage script; all CLI args extracted verbatim
- `Evo-RL/scripts/smoke_test_4090.sh` — smoke test pattern; batch sweep logic documented
- `.planning/phases/02-training-pipeline/02-CONTEXT.md` — all locked decisions (D-01 through D-24)
- `Evo-RL/pyproject.toml` — `.[pi]` extra definition; base dependencies

### Secondary (MEDIUM confidence)
- `Evo-RL/docs/reproduction_guide.md` sections 4.3-4.5 — remote env setup context (NPU-specific, but pattern reference)
- `.planning/phases/01-environment/01-01-PLAN.md.deferred` — complete rsync_to_a100.sh spec (reviewed, ready to reuse)
- `Evo-RL/scripts/resume_cloth_round1_4090.sh` — torchcodec pitfall documentation

### Tertiary (LOW confidence)
- Reproduction guide section 4.3 conda path: `/home/ma-user/anaconda3/envs/PyTorch-2.6.0/bin` — NPU-specific, A100 conda path unknown

---

## Metadata

**Confidence breakdown:**
- Script content (CLI args, paths): HIGH — extracted directly from source files
- rsync patterns: HIGH — standard tool, exact commands from CONTEXT.md
- A100 conda env behavior: MEDIUM — conda on A100 not directly verifiable; general Linux conda behavior assumed
- `su lai` interactivity constraint: HIGH — standard POSIX behavior

**Research date:** 2026-03-25
**Valid until:** 2026-04-25 (stable — scripts don't change unless training code changes)
