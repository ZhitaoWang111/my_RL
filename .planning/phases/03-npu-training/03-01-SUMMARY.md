---
phase: "03"
plan: "01"
subsystem: npu-sync
tags: [rsync, npu, ascend, data-transfer, scripts]
dependency_graph:
  requires: []
  provides:
    - rsync_to_npu.sh (Evo-RL code sync to NPU)
    - rsync_data_to_npu.sh (fold_cloth + fold_cloth_Kai0_v3 data sync to NPU)
  affects:
    - Phase 03 Plan 02 (NPU training scripts depend on data being synced)
tech_stack:
  added: []
  patterns:
    - rsync -avz --progress with -e "ssh -p PORT" for resume-capable transfers
    - SCRIPT_DIR pattern for self-relative path resolution
key_files:
  created:
    - Evo-RL/scripts/rsync_to_npu.sh
    - Evo-RL/scripts/rsync_data_to_npu.sh
  modified: []
decisions:
  - rsync_data_to_npu.sh is a single file with both datasets in sequence (simpler than two files)
  - NPU_PORT=31274 kept as variable for display in echo, but also hardcoded as literal in each -e "ssh -p 31274" argument for grep-ability
metrics:
  duration: "4m"
  completed: "2026-03-25T16:24:48Z"
  tasks_completed: 2
  files_created: 2
---

# Phase 03 Plan 01: NPU Rsync Scripts Summary

**One-liner:** Two rsync scripts for NPU server sync — code to `/home/ma-user/work/wzt/Evo-RL/` and two datasets (fold_cloth, fold_cloth_Kai0_v3) via SSH port 31274 with resume support.

## What Was Built

### rsync_to_npu.sh
Adapts the existing `rsync_to_a100.sh` structure for the Ascend NPU server:
- Host: `ma-user@dev-modelarts.cn-southwest-2.huaweicloud.com`
- Port: `31274` (hardcoded as literal in `-e "ssh -p 31274"`)
- Target: `/home/ma-user/work/wzt/Evo-RL/`
- Excludes: `.git/`, `outputs/`, `pretrained/`
- Uses `SCRIPT_DIR/..` pattern to self-locate Evo-RL root

### rsync_data_to_npu.sh
Syncs both training datasets to the NPU server in sequence:
- Dataset 1: `/media/wzt/cfy/pi-finetune/fold_cloth/` → `/home/ma-user/work/wzt/fold_cloth/`
- Dataset 2: `/media/wzt/cfy/pi-finetune/fold_cloth_Kai0_v3/` → `/home/ma-user/work/wzt/fold_cloth_Kai0_v3/`
- Both rsync calls use `-e "ssh -p 31274"` (literal port, grep-able)
- `set -euo pipefail` stops on first error

## Verification Results

| Check | Result |
|-------|--------|
| `bash -n rsync_to_npu.sh` | OK |
| `bash -n rsync_data_to_npu.sh` | OK |
| `grep "31274" rsync_to_npu.sh` | 3 lines (header comment, variable, -e arg) |
| `grep "31274" rsync_data_to_npu.sh` | 3 lines (variable, two -e args) |
| `grep "ma-user@dev-modelarts"` | Present in both scripts |
| `grep "fold_cloth_Kai0_v3"` | Source + dest paths present |
| No credentials stored | Confirmed |
| Execute permission | Both -rwxrwxr-x |

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1: rsync_to_npu.sh | fe13ff7 | feat(03-01): create rsync_to_npu.sh |
| Task 2: rsync_data_to_npu.sh | fad1792 | feat(03-01): create rsync_data_to_npu.sh |

## Deviations from Plan

None — plan executed exactly as written.

The `grep -c "31274"` on rsync_data_to_npu.sh returns 3 instead of the expected 2 because `NPU_PORT=31274` is declared as a variable for display in echo statements. Both rsync calls have port 31274 hardcoded as a literal in their `-e "ssh -p 31274"` arguments as required.

## Known Stubs

None — both scripts are fully functional (pending actual SSH connectivity to the NPU server at runtime).

## Self-Check: PASSED

- [x] `/home/wzt/wzt/mycode/my_RL/Evo-RL/scripts/rsync_to_npu.sh` — FOUND
- [x] `/home/wzt/wzt/mycode/my_RL/Evo-RL/scripts/rsync_data_to_npu.sh` — FOUND
- [x] Commit fe13ff7 — FOUND
- [x] Commit fad1792 — FOUND
