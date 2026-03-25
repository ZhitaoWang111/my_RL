# Evo-RL

## What This Is

Evo-RL 是基于 LeRobot 构建的真实世界 offline-to-online 强化学习框架，支持 AgileX PiPER 等机械臂平台。核心流程：价值函数训练（Pi*0.6）→ ACP 标注 → 策略训练（Pi0.5），通过 advantage-conditioned prompt 实现轨迹质量筛选。本仓库是团队主要开发仓库，目标是覆盖从数据采集到闭环 rollout 的完整 RL 训练流水线。

## Core Value

**完整跑通 3 步训练流水线**（conda 环境 → 权重下载 → value-train → value-infer → policy-train），在真机上完成一轮 RL 迭代。

## Requirements

### Validated

- ✓ 价值函数训练脚本 (`lerobot-value-train`) — 已实现
- ✓ ACP 标注推理脚本 (`lerobot-value-infer`) — 已实现
- ✓ 策略训练脚本 (`lerobot-train`, Pi0.5) — 已实现
- ✓ AgileX PiPER 硬件支持 (`bi_piper_follower`) — 已实现
- ✓ 多 GPU DDP 训练 (accelerate) — 已实现
- ✓ 数据采集 (`lerobot-human-inloop-record`) — 已实现

### Active

- [ ] conda 环境一键配置文档（含预训练权重下载流程）
- [ ] A100 / 4090 / NPU 三套分离训练脚本（pen 任务为基准）
- [ ] pen 任务 Round 1 完整跑通（单机多卡 4090 + 1 卡适配）
- [ ] 多任务通用化：训练脚本参数化（任务名、数据集路径、机器人配置可切换）
- [ ] 闭环 rollout：PiPER 真机 policy 部署 + 数据采集 + Round 2 迭代

### Out of Scope

- 仿真环境训练 — 项目聚焦真实世界 RL，仿真留给 LeRobot 上游
- 非 PiPER/SO101 机器人适配 — 当前 milestone 不扩展其他平台
- Web UI / 可视化仪表盘 — 使用 wandb + rerun 已覆盖监控需求

## Context

- **代码基础**: Fork 自 LeRobot 0.4.4，深度定制 value training / ACP / policy training 流程
- **当前状态**: `evo-rl` conda 环境已存在，数据集 `/home/wzt/wzt/data/pen` 已就绪；缺 `pi05_base`、`siglip-so400m-patch14-384`、`gemma-3-270m` 预训练权重
- **硬件**: 多卡 A100、多卡 RTX 4090（当前系统检测到 1 卡）、华为 NPU（8 卡）；三类硬件各维护独立训练脚本
- **任务**: pen（左臂握笔写字），双臂 SO101 数据，当前 mask 掉右臂 + 右腕相机
- **迭代方式**: Round 1 用人类 demo，Round N 追加 policy rollout 数据，ACP 标签按 round 写入 parquet

## Constraints

- **Tech Stack**: Python 3.10, PyTorch 2.7.1, Transformers 4.57.1, Accelerate 1.11.0 — 不升级上游版本
- **Hardware**: 训练脚本需覆盖 A100 / 4090 / NPU 三类，batch size 按设备显存调整
- **Data**: 数据集格式遵循 LeRobot 规范（parquet + video），ACP 字段写入 `complementary_info.*`

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| 三套独立训练脚本 | 硬件差异大（CUDA/NPU），分开维护更清晰 | 分别为 A100.sh / 4090.sh / npu.sh |
| pen 任务为基准 | 最小闭环路径，先跑通再推广 | 多任务脚本参数化在 Round 1 完成后 |
| 先跑训练再做 rollout | 验证训练流水线正确性优先于真机部署 | rollout 为后续 milestone |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-03-25 after initialization*
