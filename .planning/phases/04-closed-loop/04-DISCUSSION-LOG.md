# Phase 4: Closed Loop - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-26
**Phase:** 04-closed-loop
**Areas discussed:** 推理链路梳理, fold_cloth 任务适配

---

## 推理链路梳理 (Pipeline Walkthrough)

User requested understanding the async_inference multi-threaded pipeline before making decisions.

### Sub-topic: 推理架构总览

Presented: async_inference (gRPC multi-threaded) vs eval_bipiper.py (single-process sync) comparison table.
**User's choice:** Only care about async_inference, skip eval_bipiper.py entirely.
**Notes:** User explicitly stated: "只关心async_inference 多线程推理，无需care eval_bipiper.py"

### Sub-topic: Pipeline 深入

| Option | Description | Selected |
|--------|-------------|----------|
| action 时间聚合机制 | chunk 如何与队列中旧 action 加权融合 | ✓ |
| 处理器链路 (preprocessor/postprocessor) | make_pre_post_processors 具体步骤 | |
| 跳过，进入 fold_cloth 适配 | 已理解推理流程 | |

**User's choice:** action 时间聚合机制
**Notes:** Walked through aggregate_fn (weighted_average default), chunk_size_threshold (0.5), must_go mechanism

### Sub-topic: 更多深入

| Option | Description | Selected |
|--------|-------------|----------|
| 处理器链路 | preprocessor/postprocessor 具体步骤 | |
| obs 过滤机制 | _obs_sanity_checks 跳过重复/相似观测 | |
| 进入 fold_cloth 适配 | 开始讨论适配决定 | ✓ |

**User's choice:** 进入 fold_cloth 适配

---

## fold_cloth 任务适配

### 启动方式

| Option | Description | Selected |
|--------|-------------|----------|
| 写启动脚本 (Recommended) | 新建 run_eval_fold_cloth.sh | ✓ |
| 直接命令行 | 手动拼 CLI 参数 | |

**User's choice:** 写启动脚本

### 相机配置

| Option | Description | Selected |
|--------|-------------|----------|
| 复用 run_eval.sh 的 3 个相机 | wrist_left, wrist_right, top | ✓ |
| 根据训练时相机名重新配置 | 用 rename_map 映射 | |
| 我来告诉你相机配置 | 自定义 | |

**User's choice:** 复用 run_eval.sh 的 3 个相机

### Action 分发

| Option | Description | Selected |
|--------|-------------|----------|
| 全 14 维双臂都用 policy 输出 (Recommended) | 前 7 维左臂，后 7 维右臂 | ✓ |
| 左臂 policy + 右臂固定 | 与 pen 任务相同 | |

**User's choice:** 全 14 维双臂都用 policy 输出

---

## Claude's Discretion

- server FPS / inference_latency 默认值
- actions_per_chunk 值
- aggregate_fn 选择
- chunk_size_threshold 值

## Deferred Ideas

- 数据采集集成 (rollout 录制 for Round 2)
- NPU→CUDA checkpoint 兼容性
- 推理性能调优
- eval_bipiper.py fold_cloth 适配 (备选方案)
