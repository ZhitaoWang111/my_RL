# Requirements: Evo-RL

**Defined:** 2026-03-25
**Core Value:** 在 PiPER 真机上完整跑通一轮 offline-to-online RL 训练迭代

## v1 Requirements

### 环境配置（ENV）

- [ ] **ENV-01**: 开发者可通过文档一步重建 `evo-rl` conda 环境（Python 3.10, 所有依赖）
- [ ] **ENV-02**: 开发者可通过脚本/文档下载全部预训练权重（pi05_base、siglip-so400m-patch14-384、gemma-3-270m）
- [ ] **ENV-03**: 环境验证命令可在 10 秒内确认 CUDA、依赖、权重均就绪

### 训练脚本（TRAIN）

- [ ] **TRAIN-01**: pen Round 1 可在单卡 RTX 4090 上完整运行（value-train → value-infer → policy-train 三步）
- [ ] **TRAIN-02**: pen Round 1 可在多卡 A100 上完整运行
- [ ] **TRAIN-03**: pen Round 1 可在华为 NPU（8 卡）上完整运行
- [ ] **TRAIN-04**: 三套训练脚本（4090.sh / A100.sh / npu.sh）独立维护，batch size 和 GPU 配置按硬件适配

### 多任务通用化（TASK）

- [ ] **TASK-01**: 训练脚本通过参数（任务名、数据集路径）支持切换不同任务，不需要复制脚本
- [ ] **TASK-02**: 新任务只需提供数据集路径和特征配置（关节切片、相机排除）即可复用训练流程

### 闭环迭代（LOOP）

- [ ] **LOOP-01**: 在 PiPER 真机上运行训练好的 policy，通过 `lerobot-human-inloop-record` 采集 rollout 数据
- [ ] **LOOP-02**: rollout 数据合并进数据集后，可运行 Round 2（value 重训 + ACP 重标注 + policy 重训）

## v2 Requirements

### 可视化与监控

- **VIZ-01**: ACP 标注可视化（value 曲线叠加视频）批量生成
- **VIZ-02**: 多轮迭代训练曲线对比（Round 1 vs Round 2）

### 其他平台

- **PLAT-01**: SO101 双臂平台适配（目前已有 pen 数据，后续任务扩展）

## Out of Scope

| Feature | Reason |
|---------|--------|
| 仿真环境训练 | 聚焦真实世界 RL，仿真留给 LeRobot 上游 |
| Web UI / 监控仪表盘 | wandb + rerun 已覆盖 |
| 非 PiPER/SO101 机器人（v1）| 当前 milestone 不扩展平台 |
| 在线 RL (online rollout without human) | 当前迭代采用 human-in-the-loop 模式 |

## Traceability

_由 roadmap 创建后填充_

| Requirement | Phase | Status |
|-------------|-------|--------|
| ENV-01 ~ ENV-03 | TBD | Pending |
| TRAIN-01 ~ TRAIN-04 | TBD | Pending |
| TASK-01 ~ TASK-02 | TBD | Pending |
| LOOP-01 ~ LOOP-02 | TBD | Pending |
