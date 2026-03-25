# Roadmap: Evo-RL

## Overview

从零搭建可复现的 offline-to-online RL 训练流水线：先确保环境与权重就绪，再在多硬件上跑通 pen Round 1 完整三步训练，然后将脚本参数化以支持多任务，最终在 PiPER 真机上完成闭环 rollout 并启动 Round 2 迭代。四个阶段顺序推进，每个阶段交付一个可独立验证的能力。

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Environment** - conda 环境 + 预训练权重 + 验证命令全部就绪
- [ ] **Phase 2: Training Pipeline** - pen Round 1 三步流水线在 4090 / A100 / NPU 三类硬件全部跑通
- [ ] **Phase 3: Multi-task** - 训练脚本参数化，新任务无需复制脚本即可接入
- [ ] **Phase 4: Closed Loop** - PiPER 真机部署 + rollout 数据采集 + Round 2 完整迭代

## Phase Details

### Phase 1: Environment
**Goal**: 开发者可以在任意目标机器上一步重建训练环境并验证就绪
**Depends on**: Nothing (first phase)
**Requirements**: ENV-01, ENV-02, ENV-03
**Success Criteria** (what must be TRUE):
  1. 开发者按照文档执行后，`evo-rl` conda 环境可成功激活，所有依赖可导入
  2. pi05_base、siglip-so400m-patch14-384、gemma-3-270m 三个预训练权重通过脚本/文档下载到位
  3. 环境验证命令在 10 秒内输出 CUDA 可用、依赖版本、权重路径均通过的确认信息
**Plans:** 2 plans
Plans:
- [ ] 01-01-PLAN.md — Weight download script (download_weights.sh) + A100 rsync script (rsync_to_a100.sh) [ENV-02]
- [ ] 01-02-PLAN.md — Environment verification script (verify_env.py) + setup documentation (setup_guide.md) [ENV-01, ENV-03]

### Phase 2: Training Pipeline
**Goal**: pen Round 1 三步训练流水线（value-train → value-infer → policy-train）在全部三类硬件上可独立运行完毕
**Depends on**: Phase 1
**Requirements**: TRAIN-01, TRAIN-02, TRAIN-03, TRAIN-04
**Success Criteria** (what must be TRUE):
  1. 在单卡 RTX 4090 上执行 `4090.sh`，value-train、value-infer、policy-train 三步全部无报错完成
  2. 在多卡 A100 上执行 `A100.sh`，三步流水线全部无报错完成
  3. 在华为 NPU（8 卡）上执行 `npu.sh`，三步流水线全部无报错完成
  4. 三个脚本各自独立维护，batch size 和 GPU 配置分别按设备显存适配，互不耦合
**Plans**: TBD

### Phase 3: Multi-task
**Goal**: 训练脚本通过参数切换任务，新任务无需复制脚本即可接入
**Depends on**: Phase 2
**Requirements**: TASK-01, TASK-02
**Success Criteria** (what must be TRUE):
  1. 向训练脚本传入不同的任务名和数据集路径参数，脚本无需修改即可切换任务运行
  2. 为新任务只提供数据集路径和特征配置（关节切片、相机排除）后，三步训练流程可正常执行
**Plans**: TBD

### Phase 4: Closed Loop
**Goal**: 在 PiPER 真机上完成 policy 部署、rollout 数据采集和 Round 2 完整迭代，验证闭环 RL 可行性
**Depends on**: Phase 2
**Requirements**: LOOP-01, LOOP-02
**Success Criteria** (what must be TRUE):
  1. 训练好的 policy 在 PiPER 真机上通过 `lerobot-human-inloop-record` 驱动机械臂执行任务并采集 rollout 数据
  2. rollout 数据合并进数据集后，Round 2（value 重训 + ACP 重标注 + policy 重训）可完整运行至结束
  3. Round 2 产出的 policy checkpoint 可在真机上再次部署验证
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Environment | 0/2 | Planning complete | - |
| 2. Training Pipeline | 0/? | Not started | - |
| 3. Multi-task | 0/? | Not started | - |
| 4. Closed Loop | 0/? | Not started | - |
