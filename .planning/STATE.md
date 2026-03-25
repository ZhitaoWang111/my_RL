---
gsd_state_version: 1.0
milestone: v3.0
milestone_name: milestone
status: Phase complete — ready for verification
stopped_at: Completed 03-02-PLAN.md (NPU training scripts — merged 2-round)
last_updated: "2026-03-25T16:31:43.050Z"
progress:
  total_phases: 4
  completed_phases: 3
  total_plans: 5
  completed_plans: 5
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-25)

**Core value:** 在 PiPER 真机上完整跑通一轮 offline-to-online RL 训练迭代
**Current focus:** Phase 03 — npu-training

## Current Position

Phase: 03 (npu-training) — EXECUTING
Plan: 2 of 2

## Performance Metrics

**Velocity:**

- Total plans completed: 0
- Average duration: -
- Total execution time: -

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

**Recent Trend:**

- Last 5 plans: -
- Trend: -

*Updated after each plan completion*
| Phase 02 P02 | 4 | 2 tasks | 2 files |
| Phase 02 P01 | 8 | 3 tasks | 3 files |
| Phase 03 P01 | 4m | 2 tasks | 2 files |
| Phase 03-npu-training P02 | 3min | 1 tasks | 1 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- 三套独立训练脚本（A100.sh / 4090.sh / npu.sh）分开维护，CUDA/NPU 差异隔离
- pen 任务为基准，先跑通 Round 1 再参数化多任务
- 先跑训练再做 rollout，验证流水线正确性优先
- [Phase 02]: fold_cloth 全 14 维特征: EXCLUDE_CAMERAS=STATE_SLICE=ACTION_SLICE=空字符串，区别于 pen 任务 4090 脚本的 0:7 切片
- [Phase 02]: A100 WORK_DIR 硬编码为 /moganshan/afs_a/lai/Evo-RL，PRETRAINED_DIR 为绝对路径，不随 WORK_DIR 变化
- [Phase 02]: setup_a100_env.sh generates remote script + prints su lai manual steps instead of automating (interactive TTY required)
- [Phase 02]: rsync_weights_to_a100.sh checks source disk mount existence before transfer
- [Phase 02]: SSH port hardcoded as literal 10322 in rsync -e argument for grep-able verification
- [Phase 03]: rsync_data_to_npu.sh is single file with both datasets in sequence; NPU_PORT=31274 as variable + literal hardcode in -e args for display and grep-ability
- [Phase 03-npu-training]: Merged Kai0+fold_cloth into single train_cloth_full_npu.sh: continuous 2-round training on 2x Ascend 910B without manual intervention between rounds

### Pending Todos

None yet.

### Blockers/Concerns

- **[NEW]** Kai0 parquet 文件是 Git LFS 指针，需先 `git lfs pull` 才能使用
- **[NEW]** Kai0 v2.1 格式需迁移到 v3.0 后才能进入 3 阶段训练
- **[DEFERRED]** 预训练权重（pi05_base、siglip-so400m-patch14-384、gemma-3-270m）尚未下载 — Phase 2 前处理
- **[DEFERRED]** 当前系统检测到 1 卡 RTX 4090，多卡和 NPU 脚本需在对应硬件上分别验证 — Phase 2

### Deferred Plans

以下旧 Phase 1 计划已搁置，Phase 2 开始前再恢复：

- `01-01-PLAN.md` — download_weights.sh + rsync_to_a100.sh [ENV-02]
- `01-02-PLAN.md` — verify_env.py + setup_guide.md [ENV-01, ENV-03]

## Session Continuity

Last session: 2026-03-25T16:31:43.049Z
Stopped at: Completed 03-02-PLAN.md (NPU training scripts — merged 2-round)
Resume file: None
