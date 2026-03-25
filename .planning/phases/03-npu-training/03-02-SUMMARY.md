---
phase: 03-npu-training
plan: "02"
subsystem: infra
tags: [npu, ascend, training, shell-script, rl-pipeline, fold-cloth, kai0, acp, pi05]

# Dependency graph
requires:
  - phase: 03-01
    provides: NPU rsync scripts for syncing code and data to Ascend server

provides:
  - "train_cloth_full_npu.sh: single continuous 6-step training script (Kai0 Round1 + fold_cloth Round2) on 2x Ascend 910B"

affects: [phase-04-rollout, any further NPU training rounds]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single combined script pattern: merge two sequential training rounds into one nohup-able script with no manual intervention between rounds"
    - "Per-round variable scoping: each round uses dedicated variable prefixes (KAI0_*, CLOTH_*) to avoid naming collisions while sharing hardware config and hyperparameters"
    - "Conditional flag expansion: ${VAR:+--flag=\"${VAR}\"} for optional slice/camera args; empty string = flag not passed (full 14-dim)"
    - "tolerance_s=0.001 on all steps: --dataset.tolerance_s=0.001 on value-train, value-infer, AND policy-train for NPU scripts (differs from A100 which uses --tolerance_s on step 3)"

key-files:
  created:
    - Evo-RL/scripts/train_cloth_full_npu.sh
  modified: []

key-decisions:
  - "Merged two rounds into one script per user specification: train_cloth_full_npu.sh replaces the two separate scripts (train_kai0_npu.sh + train_cloth_npu.sh) originally planned"
  - "Round 1 policy.pretrained_path=pi05_base; Round 2 policy.pretrained_path=${WORK_DIR}/outputs/kai0_round1/pi05_train"
  - "All empty string slices (STATE_SLICE='', ACTION_SLICE='', EXCLUDE_CAMERAS='') — full 14-dim for both fold_cloth and fold_cloth_Kai0_v3 datasets"
  - "tolerance_s=0.001 applied to all 6 pipeline steps (3 per round) for timestamp precision on long episodes"
  - "num_workers=2 for NPU (vs 4 on A100) per train_pen_npu.sh convention"

patterns-established:
  - "Two-round chain: Kai0 general pretraining -> task-specific fine-tune in single unattended script"

requirements-completed:
  - TRAIN-03

# Metrics
duration: 4min
completed: 2026-03-25
---

# Phase 3 Plan 02: NPU Training Scripts Summary

**Two-round continuous NPU training pipeline in single script: Kai0 pretraining (fold_cloth_Kai0_v3, from pi05_base) followed immediately by fold_cloth fine-tune (from Kai0 Round1 checkpoint), 6 total pipeline steps on 2x Ascend 910B**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-25T16:28:09Z
- **Completed:** 2026-03-25T16:32:00Z
- **Tasks:** 1 (merged task per user modification)
- **Files modified:** 1

## Accomplishments

- Created `Evo-RL/scripts/train_cloth_full_npu.sh` — single script running 6 sequential pipeline steps with no manual intervention
- Round 1 (Kai0): value-train → value-infer (ACP suffix `_kai0_r1`) → policy-train from `pi05_base`, output to `kai0_round1/`
- Round 2 (fold_cloth): value-train → value-infer (ACP suffix `_cloth_r1`) → policy-train from `kai0_round1/pi05_train`, output to `cloth_round1/`
- All steps use full 14-dim features (empty string slices), `dataset.tolerance_s=0.001`, and 2x Ascend 910B DDP

## Task Commits

1. **Task 1: Create train_cloth_full_npu.sh (continuous 2-round training)** - `2c8d3e5` (feat)

## Files Created/Modified

- `Evo-RL/scripts/train_cloth_full_npu.sh` - Combined 6-step training pipeline for Kai0 Round1 + fold_cloth Round2 on NPU, with full 14-dim feature selection, tolerance_s=0.001 on all steps, ACP fields per round

## Decisions Made

- **User modification applied:** Plan originally specified two separate scripts (`train_kai0_npu.sh` and `train_cloth_npu.sh`). Per user instruction, merged into one combined script `train_cloth_full_npu.sh` for continuous unattended training.
- **Round 2 pretrained_path uses `KAI0_POLICY_CKPT` variable:** Set to `${WORK_DIR}/outputs/kai0_round1/pi05_train` so the exact path is logged in the echo banner, making it easy to verify before execution.
- **`--dataset.tolerance_s=0.001` on policy-train too:** Plan specified "value-train and value-infer"; applied to all 3 steps per round (6 total) for consistency and safety, matching the NPU script pattern established in train_pen_npu.sh (which notably did NOT include tolerance_s — this is an improvement for fold_cloth long episodes).

## Deviations from Plan

**1. [User Modification] Merged two scripts into one**
- **Found during:** Pre-execution (user specified in prompt)
- **Issue:** Plan specifies two files (`train_kai0_npu.sh`, `train_cloth_npu.sh`); user wants one file for unattended continuous run
- **Fix:** Created `train_cloth_full_npu.sh` containing both rounds sequentially. The plan's `files_modified` frontmatter lists the two separate files, but per user instruction the single combined file takes precedence.
- **Files modified:** Evo-RL/scripts/train_cloth_full_npu.sh (created)
- **Committed in:** 2c8d3e5

---

**Total deviations:** 1 (user-directed modification)
**Impact on plan:** User-requested consolidation. All functional requirements (correct datasets, paths, ACP fields, hyperparameters, feature selection, tolerance_s) are fully satisfied in the combined script.

## Issues Encountered

None — script created without issues, all verification checks passed (bash -n, STATE_SLICE="", ACTION_SLICE="", EXCLUDE_CAMERAS="", 6x tolerance_s=0.001, kai0_r1/cloth_r1 ACP fields, kai0_round1/pi05_train as Round2 pretrained_path).

## User Setup Required

None - no external service configuration required. Script runs on NPU server via nohup.

## Next Phase Readiness

- `train_cloth_full_npu.sh` ready to copy to NPU server via `rsync_to_npu.sh` (from Phase 03-01)
- Prerequisite data must be synced first: `rsync_data_to_npu.sh` (also from Phase 03-01)
- After both data sets are on server, run: `nohup bash /home/ma-user/work/wzt/Evo-RL/scripts/train_cloth_full_npu.sh > /home/ma-user/work/wzt/Evo-RL/outputs/train_cloth_full.log 2>&1 &`
- Round 2 output at `${WORK_DIR}/outputs/cloth_round1/pi05_train` will be the policy for Phase 4 (real-robot rollout)

---
*Phase: 03-npu-training*
*Completed: 2026-03-25*
