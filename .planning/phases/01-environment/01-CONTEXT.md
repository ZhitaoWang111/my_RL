# Phase 1: 数据兼容性检查 - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

> **⚠️ 方向变更说明（2026-03-25）**
> Phase 1 原计划聚焦于环境配置（download_weights.sh / rsync_to_a100.sh / verify_env.py / setup_guide.md）。
> 用户决定将 Phase 1 重新聚焦于**数据集兼容性检查**，优先确认两个叠衣服数据集能否进入3阶段训练。
> 旧的 ENV 计划（01-01-PLAN.md、01-02-PLAN.md）保留但标记为 deferred，后续 Phase 2 前再执行。

<domain>
## Phase Boundary

Phase 1 交付：一个可运行的 Python 数据集检查脚本（`Evo-RL/scripts/check_datasets.py`），输出两个数据集与 Evo-RL 3 阶段训练流水线的兼容性报告，明确列出阻塞项和所需转换步骤。

本 Phase 聚焦于：
- 检查 fold_cloth（自采集，v3.0）与 3 阶段训练流水线的兼容性
- 检查 Kai0_dataset（开源，v2.1）的格式问题和转换需求
- 明确 Kai0 用于**全流水线预训练**的路径和阻塞项
- 生成结构化的兼容性报告供后续 Phase 参考

**不在本 Phase 范围内：** 实际数据集格式转换、权重下载、A100 迁移、训练脚本执行。

</domain>

<decisions>
## Implementation Decisions

### 数据集基本情况

| 属性 | fold_cloth | Kai0_dataset |
|------|-----------|--------------|
| 路径 | `/media/wzt/cfy/pi-finetune/fold_cloth` | `/media/wzt/cfy/pi-finetune/Kai0_dataset/Task_A/base` |
| 版本 | v3.0 ✓ | v2.1 ⚠️ |
| 机器人 | bi_piper_follower | agilex |
| Episodes | 50 | 3,055 |
| Frames | 73,445 | 3,362,369 |
| FPS | 30 | 30 |
| Action shape | [14] | [14] |
| State shape | [14] | [14] |
| EndEffector 字段 | ✓ (action_ee, obs.state_ee) | ✗ |
| Named fields | ✓ | ✗ (null) |
| 相机 | left_wrist_left, left_top, right_wrist_right | top_head, hand_left, hand_right |
| Parquet 数据 | ✓ 真实数据 | ⚠️ Git LFS 指针 |

### Kai0 规划用途

- **D-01**: Kai0 的目标用途为**全流水线预训练**：先在 Kai0 上完整运行 3 阶段（value-train → value-infer → policy-train），产出 checkpoint，再用 fold_cloth 做 fine-tune。

### 检查脚本设计

- **D-02**: 产出形式：Python 脚本 `Evo-RL/scripts/check_datasets.py`，运行即输出兼容性报告
- **D-03**: 脚本支持两种调用方式：
  1. 默认：硬编码两个数据集路径（fold_cloth + Kai0）
  2. 自定义：`--datasets /path/to/ds1 /path/to/ds2 [...]`
- **D-04**: 不加载任何模型，不读取 parquet 内容（只读 meta/info.json 和 meta/stats.json），确保运行速度快

### Kai0 已知问题清单（报告必须涵盖）

- **D-05**: 版本不兼容：Kai0 v2.1 vs 代码库 v3.0，需要执行 v2.1→v3.0 迁移脚本（`backward_compatibility.py` 中有迁移路径）
- **D-06**: Git LFS 指针：Kai0 的 parquet 文件是 LFS 指针（131 bytes），需先 `cd /media/wzt/cfy/pi-finetune/Kai0_dataset/Task_A/base && git lfs pull` 拉取真实数据
- **D-07**: 相机名称差异：Kai0 的相机名称（top_head/hand_left/hand_right）与 fold_cloth（left_wrist_left/left_top/right_wrist_right）无重叠，需在后续 Phase 决定映射策略
- **D-08**: 无命名字段：Kai0 所有 feature 的 `names` 字段为 null，训练时无法按名称选择关节
- **D-09**: 无 EndEffector 字段：Kai0 缺少 `action_ee` 和 `observation.state_ee`，如 Pi*0.6 value 训练用到这些字段需额外处理

### 报告格式（Claude 自由发挥）

- **D-10**: 报告输出格式由 Claude 设计，要求：清晰显示每个数据集的状态（✓/⚠️/✗），阻塞项有编号，每个阻塞项有具体的修复命令或指引

</decisions>

<specifics>
## Specific Ideas

- 检测 LFS 指针的方法：读取 parquet 文件前几字节，若包含 `version https://git-lfs.github.com` 则判定为 LFS 指针
- 版本兼容性检查：读取 `meta/info.json` 的 `codebase_version` 字段，与 `"v3.0"` 比较（主版本号必须匹配）
- 脚本调用示例：
  ```bash
  # 默认检查两个数据集
  python Evo-RL/scripts/check_datasets.py

  # 自定义数据集路径
  python Evo-RL/scripts/check_datasets.py \
    --datasets /media/wzt/cfy/pi-finetune/fold_cloth \
               /media/wzt/cfy/pi-finetune/Kai0_dataset/Task_A/base
  ```
- 相机名差异检测：读取 meta/info.json 中 features 字段，过滤 dtype 为 "video" 或 "image" 的条目

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 数据集格式
- `Evo-RL/src/lerobot/datasets/lerobot_dataset.py` — CODEBASE_VERSION = "v3.0"，版本检查逻辑（lines 81, 164）
- `Evo-RL/src/lerobot/datasets/backward_compatibility.py` — v2.1→v3.0 迁移路径参考

### 训练脚本参考
- `Evo-RL/scripts/train_pen_4090.sh` — 3 阶段训练命令结构、数据集路径约定

### 数据集路径
- `fold_cloth`: `/media/wzt/cfy/pi-finetune/fold_cloth` (v3.0, 已就绪)
- `Kai0`: `/media/wzt/cfy/pi-finetune/Kai0_dataset/Task_A/base` (v2.1, 需转换)

</canonical_refs>

<code_context>
## Existing Code Insights

### 3 阶段训练数据集要求

来自探索 `train_pen_4090.sh` 和 `lerobot_dataset.py` 的结论：

**版本要求**
- `CODEBASE_VERSION = "v3.0"` （`lerobot_dataset.py:81`）
- 主版本号必须匹配，否则抛出 `BackwardCompatibilityError`
- `check_version_compatibility()` 在 `lerobot_dataset.py:164` 调用

**必需字段**（DEFAULT_FEATURES）
```
timestamp, frame_index, episode_index, index, task_index
action, observation.state
observation.images.{camera_name}  (至少一路相机)
```

**Stage 2 写入字段**（运行后追加到 parquet）
```
complementary_info.value_r1
complementary_info.advantage_r1
complementary_info.acp_indicator_r1
```

**目录结构要求**（v3.0）
```
dataset_root/
├── meta/info.json          # codebase_version, robot_type, features, fps
├── meta/stats.json         # 所有字段的均值/方差
├── meta/tasks.parquet
├── meta/episodes/chunk-{N}/file-{N}.parquet
├── data/chunk-{N}/file-{N}.parquet
└── videos/{camera}/chunk-{N}/file-{N}.mp4
```

**v2.1 目录结构**（Kai0 的格式）
```
dataset_root/
├── meta/info.json          # codebase_version, robot_type, features, fps
├── meta/episodes.jsonl     # (jsonl, 不是 parquet)
├── meta/episodes_stats.jsonl
├── meta/tasks.jsonl
└── data/chunk-{N}/episode_{N:06d}.parquet  # 文件命名不同
```

</code_context>

<deferred>
## Deferred Ideas

### 原 Phase 1 ENV 计划（暂搁置）
- `download_weights.sh` — 下载 pi05_base / siglip / gemma-3-270m 预训练权重
- `rsync_to_a100.sh` — 代码/权重迁移到 A100 NAS 存储
- `verify_env.py` — 环境验证脚本（CUDA / 依赖版本 / 权重路径）
- `setup_guide.md` — A100 + 4090 环境搭建文档

以上内容在 Phase 2 开始前（训练脚本开发前）需要完成，后续在合适时机重新规划。

### 数据转换工作（Phase 2 前）
- Kai0 v2.1 → v3.0 格式迁移
- Kai0 Git LFS pull（拉取真实 parquet 数据）
- 相机名称映射策略设计（Kai0 相机 vs fold_cloth 相机）
- Kai0 EndEffector 字段补充（或确认 Pi*0.6 是否需要该字段）

</deferred>

---

*Phase: 01-environment (重新聚焦为数据兼容性检查)*
*Context gathered: 2026-03-25 via /gsd:discuss-phase*
