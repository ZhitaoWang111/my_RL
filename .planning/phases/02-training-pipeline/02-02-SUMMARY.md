---
phase: 02-training-pipeline
plan: "02"
subsystem: training-scripts
tags: [A100, training-pipeline, fold-cloth, DDP, smoke-test]
dependency_graph:
  requires: []
  provides:
    - Evo-RL/scripts/train_pen_A100.sh
    - Evo-RL/scripts/smoke_test_A100.sh
  affects:
    - A100 training pipeline execution
tech_stack:
  added: []
  patterns:
    - "eval ${LAUNCH} $(which lerobot-*) pattern for multi-GPU launch"
    - "Conditional bash parameter expansion: ${VAR:+--flag=value}"
key_files:
  created:
    - Evo-RL/scripts/train_pen_A100.sh
    - Evo-RL/scripts/smoke_test_A100.sh
  modified: []
decisions:
  - "fold_cloth task uses all 14 dimensions (EXCLUDE_CAMERAS=STATE_SLICE=ACTION_SLICE='') unlike pen task on 4090 which uses 0:7 slice for left arm only"
  - "WORK_DIR hardcoded as /moganshan/afs_a/lai/Evo-RL instead of dynamic dirname — required for A100 shared storage"
  - "PRETRAINED_DIR as absolute path /moganshan/afs_a/lai/pretrained — not relative to WORK_DIR (Pitfall 6 / D-13)"
  - "smoke_test_A100.sh uses _smoke suffix for ACP fields to avoid polluting Round 1 _r1 fields"
metrics:
  duration: "4 minutes"
  completed: "2026-03-25"
  tasks_completed: 2
  files_created: 2
---

# Phase 02 Plan 02: A100 Training Scripts Summary

4-card A100 training pipeline scripts for fold_cloth task using full 14-dimension action/state space, including both full training (train_pen_A100.sh) and quick environment validation (smoke_test_A100.sh).

## Objective

Created two A100 training scripts for the pen Round 1 three-stage training pipeline: a full training script and a 10-step smoke test for environment validation.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | 创建 train_pen_A100.sh (4 卡 A100 完整训练) | Evo-RL@36720f2 | Evo-RL/scripts/train_pen_A100.sh |
| 2 | 创建 smoke_test_A100.sh (A100 冒烟测试) | Evo-RL@6a99fba | Evo-RL/scripts/smoke_test_A100.sh |

## Key Implementation Details

### D-24 Feature Selection: fold_cloth Full 14 Dimensions

The critical difference from train_pen_4090.sh is the feature selection variables:

| Variable | 4090 (pen task) | A100 (fold_cloth task) |
|----------|-----------------|------------------------|
| `EXCLUDE_CAMERAS` | `'["observation.images.right_wrist_right"]'` | `""` (keep all 3 cameras) |
| `STATE_SLICE` | `"0:7"` (left arm only) | `""` (all 14 dims: both arms) |
| `ACTION_SLICE` | `"0:7"` (left arm only) | `""` (all 14 dims: both arms) |

The pen task on 4090 masks the right arm because pen-writing only uses the left arm. fold_cloth is a bimanual task requiring both arms and all 3 cameras.

### A100 vs 4090: 8 Key Differences

1. **Comment title**: `2x RTX 4090 (24GB)` → `4x A100 (80GB)`
2. **Usage comments**: `train_pen_4090.sh` → `train_pen_A100.sh`
3. **WORK_DIR**: Dynamic `$(cd "$(dirname "$0")/.." && pwd)` → hardcoded `/moganshan/afs_a/lai/Evo-RL`
4. **DATA_DIR**: `/home/wzt/wzt/data/pen` → `/moganshan/afs_a/lai/data/fold_cloth`
5. **PRETRAINED_DIR**: `${WORK_DIR}/pretrained` → `/moganshan/afs_a/lai/pretrained` (absolute, not relative)
6. **OUTPUT_DIR**: `${WORK_DIR}/outputs/pen_round1_4090` → `${WORK_DIR}/outputs/pen_round1_A100`
7. **NUM_GPUS + LAUNCH**: 2 cards `CUDA_VISIBLE_DEVICES=0,1` → 4 cards `CUDA_VISIBLE_DEVICES=0,1,2,3`
8. **Feature selection**: 7-dim (left arm) → 14-dim (both arms, fold_cloth full feature set)
9. **job_name suffixes**: `_4090` → `_A100` (in all 3 stages)
10. **torchcodec warning**: Added before value-infer step

### smoke_test_A100.sh Design

- `SMOKE_STEPS=10` — minimum steps to verify pipeline runs (not to train)
- Fixed `batch=8` — no multi-batch sweep (A100 has 80GB, no OOM risk at batch=8)
- **Smoke-specific ACP fields**: uses `_smoke` suffix (`complementary_info.acp_indicator_smoke`) to avoid overwriting Round 1 `_r1` fields
- Cleans output dirs (`rm -rf`) before each stage for clean repeat runs
- Summary result check at end (looks for `checkpoints/` subdirectory)
- Path config identical to train_pen_A100.sh (WORK_DIR, DATA_DIR, PRETRAINED_DIR)

### Steps vs Effective Batch Size

| Script | Per-device batch | GPUs | Effective batch |
|--------|-----------------|------|-----------------|
| train_pen_A100.sh (value) | 8 | 4 | **32** |
| train_pen_A100.sh (policy) | 8 | 4 | **32** |
| smoke_test_A100.sh | 8 | 4 | 32 |
| train_pen_4090.sh | 8 | 2 | 16 |

## Verification Results

All checks passed:

```
bash -n train_pen_A100.sh      # syntax OK
bash -n smoke_test_A100.sh     # syntax OK
CUDA_VISIBLE_DEVICES=0,1,2,3   # confirmed
WORK_DIR="/moganshan/afs_a/lai/Evo-RL"  # confirmed
EXCLUDE_CAMERAS=""             # confirmed
STATE_SLICE=""                 # confirmed
ACTION_SLICE=""                # confirmed
SMOKE_STEPS=10                 # confirmed
torchcodec warning present     # confirmed
4090/0:7/right_wrist_right leak check  # clean (no leakage)
```

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None — both scripts are complete and independently executable. Data and weights availability on A100 is a deployment precondition, not a stub.

## Self-Check: PASSED

Files exist:
- FOUND: /home/wzt/wzt/mycode/my_RL/Evo-RL/scripts/train_pen_A100.sh
- FOUND: /home/wzt/wzt/mycode/my_RL/Evo-RL/scripts/smoke_test_A100.sh

Commits exist:
- Evo-RL@36720f2 (train_pen_A100.sh)
- Evo-RL@6a99fba (smoke_test_A100.sh)
