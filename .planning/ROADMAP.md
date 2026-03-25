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
**Goal**: 数据集兼容性检查 — 确认 fold_cloth (v3.0) 与 Kai0_dataset (v2.1) 能否进入 3 阶段训练流水线，并明确 Kai0 的阻塞项和转换步骤
**Depends on**: Nothing (first phase)
**Requirements**: ENV-01, ENV-02, ENV-03
**Success Criteria** (what must be TRUE):
  1. `python Evo-RL/scripts/check_datasets.py` 运行输出兼容性报告，fold_cloth 显示 COMPATIBLE，Kai0 显示 NEEDS CONVERSION
  2. Kai0 的 4 个阻塞项（LFS 指针、v2.1 版本、文件命名、stats.json 缺失）全部有编号和可执行的修复命令
  3. 脚本无外部依赖（stdlib only），在任意有 Python 3.10 的环境中均可运行
**Plans:** 1 plan
Plans:
- [ ] 01-01-PLAN.md — Dataset compatibility checker script (check_datasets.py) [ENV-01]

### Phase 2: Training Pipeline
**Goal**: pen Round 1 三步训练流水线（value-train → value-infer → policy-train）在全部三类硬件上可独立运行完毕
**Depends on**: Phase 1
**Requirements**: TRAIN-01, TRAIN-02, TRAIN-03, TRAIN-04
**Success Criteria** (what must be TRUE):
  1. 在单卡 RTX 4090 上执行 `4090.sh`，value-train、value-infer、policy-train 三步全部无报错完成
  2. 在多卡 A100 上执行 `A100.sh`，三步流水线全部无报错完成
  3. 在华为 NPU（8 卡）上执行 `npu.sh`，三步流水线全部无报错完成
  4. 三个脚本各自独立维护，batch size 和 GPU 配置分别按设备显存适配，互不耦合
**Plans:** 2 plans
Plans:
- [ ] 02-01-PLAN.md — A100 部署脚本（rsync_to_a100.sh、rsync_weights_to_a100.sh、setup_a100_env.sh）[TRAIN-02, TRAIN-04]
- [ ] 02-02-PLAN.md — A100 训练脚本（train_pen_A100.sh、smoke_test_A100.sh）[TRAIN-01, TRAIN-02, TRAIN-03, TRAIN-04]

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
| 1. Environment | 0/1 | Planning complete | - |
| 2. Training Pipeline | 0/2 | Planning complete | - |
| 3. Multi-task | 0/? | Not started | - |
| 4. Closed Loop | 0/? | Not started | - |
