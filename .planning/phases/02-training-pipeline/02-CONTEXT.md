# Phase 2: A100 环境部署 + 训练流水线 - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 2 交付两件事：
1. **A100 环境部署**：代码 + 预训练权重 rsync 到 A100，conda 环境在 A100 上就绪
2. **A100 训练脚本**：`train_pen_A100.sh` — 4 卡 A100 三阶段训练流水线

本 Phase 聚焦于：
- 创建 `Evo-RL/scripts/rsync_to_a100.sh`（代码传输）
- 创建 `Evo-RL/scripts/rsync_weights_to_a100.sh`（权重传输，18GB）
- 创建 `Evo-RL/scripts/train_pen_A100.sh`（4 卡 A100 三阶段训练）
- 创建 `Evo-RL/scripts/setup_a100_env.sh`（A100 conda 环境初始化）
- 可选：smoke test 脚本验证 A100 环境就绪

**不在本 Phase 范围内：**
- 数据集上传（fold_cloth / Kai0 数据后续单独处理）
- NPU 训练脚本（已有 `train_pen_npu.sh` 参考，Phase 3 再完善）
- PiPER 真机 rollout

**安全约束（SECURITY）：** 任何规划文档、脚本文件中均不存储 A100 账号密码。
所有需要密码的操作通过 `Evo-RL/A100_login.txt` 在本地查阅。
脚本中的 SSH/rsync 命令只写主机/端口，不写密码（交互式输入）。

</domain>

<decisions>
## Implementation Decisions

### A100 连接信息

- **D-01:** A100 连接命令：`ssh moganshan@180.184.148.169 -p 10322`
- **D-02:** 登录后切换账号：`su lai`（个人目录挂载点：`/moganshan/afs_a/lai`）
- **D-03:** 连接详情存储在 `Evo-RL/A100_login.txt`，**不写入任何脚本或规划文档**

### A100 GPU 配置

- **D-04:** A100 共 8 张卡，本项目最多使用 **4 张**（其余供其他同事使用）
- **D-05:** CUDA_VISIBLE_DEVICES 设为 `0,1,2,3`（4 卡）
- **D-06:** accelerate launch --num_processes=4 --mixed_precision=bf16
- **D-07:** per-device batch size = 8（与 4090 / NPU 对齐，A100 显存充裕可按需调大）
  - Value 训练 effective batch = 8 × 4 = **32**
  - Policy 训练 effective batch = 8 × 4 = **32**

### 代码传输（rsync）

- **D-08:** 源路径：本地 `Evo-RL/`（项目根）
- **D-09:** 目标路径：`/moganshan/afs_a/lai/Evo-RL/`（A100 共享存储）
- **D-10:** 排除项：`.git`，`outputs/`，`pretrained/`
- **D-11:** rsync 参数：`-avz --progress -e "ssh -p 10322"`

### 预训练权重传输

- **D-12:** 权重源路径：`/media/wzt/jzh/Evo-RL/pretrained/`（本地，已确认）
  - pi05_base: 14GB
  - siglip-so400m-patch14-384: 3.3GB
  - gemma-3-270m: 549MB
  - paligemma-3b-pt-224: 21MB（tokenizer）
  - 总计：约 18GB
- **D-13:** 权重目标路径：`/moganshan/afs_a/lai/pretrained/`（A100 共享存储）
- **D-14:** 传输方式：rsync `-avz --progress -e "ssh -p 10322"`（支持断点续传）

### 数据集

- **D-15:** 本 Phase 不上传数据集（fold_cloth 和 Kai0 后续单独处理）
- **D-16:** train_pen_A100.sh 中 `DATA_DIR` 写为 `/moganshan/afs_a/lai/data/fold_cloth`（占位，数据上传后启用）

### A100 conda 环境

- **D-17:** 环境名：`evo-rl`，Python 3.10
- **D-18:** 安装方式：`cd /moganshan/afs_a/lai/Evo-RL && pip install -e .`（editable install）
- **D-19:** 不从本地打包迁移 conda env，直接在 A100 重新安装
- **D-20:** 版本漂移（transformers 4.53.3 vs 4.57.1 等）不强制同步，文档记录即可
- **D-21:** 若 `evo-rl` 环境已存在，setup 脚本跳过创建，直接进行 pip install

### A100 训练脚本

- **D-22:** 脚本命名：`Evo-RL/scripts/train_pen_A100.sh`
- **D-23:** 以 `train_pen_4090.sh` 为模板，修改以下字段：
  | 字段 | 4090 | A100 |
  |------|------|------|
  | `WORK_DIR` | 本地路径 | `/moganshan/afs_a/lai/Evo-RL` |
  | `DATA_DIR` | `/home/wzt/wzt/data/pen` | `/moganshan/afs_a/lai/data/fold_cloth` |
  | `PRETRAINED_DIR` | `${WORK_DIR}/pretrained` | `/moganshan/afs_a/lai/pretrained` |
  | `OUTPUT_DIR` | `${WORK_DIR}/outputs/pen_round1_4090` | `${WORK_DIR}/outputs/pen_round1_A100` |
  | `NUM_GPUS` | 2 | 4 |
  | `LAUNCH` | `CUDA_VISIBLE_DEVICES=0,1 ...` | `CUDA_VISIBLE_DEVICES=0,1,2,3 ...` |
  | `VALUE_TRAIN_BATCH` | 8 | 8（可选：16）|
  | `PI05_BATCH` | 8 | 8（可选：16）|
  | 注释标题 | "2x RTX 4090 (24GB)" | "4x A100 (80GB)" |
- **D-24:** **特征选择：fold_cloth 任务使用全部 14 维动作空间，不屏蔽右臂数据**
  - `EXCLUDE_CAMERAS=""`（空字符串，保留全部 3 个相机）
  - `STATE_SLICE=""`（空字符串，使用全部 14 维状态）
  - `ACTION_SLICE=""`（空字符串，使用全部 14 维动作）
  - 与 4090 脚本的 `STATE_SLICE="0:7"` / `ACTION_SLICE="0:7"` 不同，不能直接复制

- **D-25:** Phase 2 必须交付两个脚本：
  1. `train_pen_A100.sh` — 正式训练脚本（完整 3 阶段，大步数）
  2. `smoke_test_A100.sh` — 冒烟测试脚本（验证环境就绪，小步数快速跑通）

### Claude 自由决定

- rsync 脚本是合并一个（含 code/weights/all 子命令）还是分两个文件
- smoke_test_A100.sh 的具体步数（参考 smoke_test_4090.sh 的配置）
- setup_a100_env.sh 的具体结构

</decisions>

<specifics>
## Specific Ideas

### 代码传输参考命令
```bash
rsync -avz --progress \
    --exclude='.git' \
    --exclude='outputs/' \
    --exclude='pretrained/' \
    /home/wzt/wzt/mycode/my_RL/Evo-RL/ \
    moganshan@180.184.148.169:/moganshan/afs_a/lai/Evo-RL/ \
    -e "ssh -p 10322"
```

### 权重传输参考命令
```bash
rsync -avz --progress \
    /media/wzt/jzh/Evo-RL/pretrained/ \
    moganshan@180.184.148.169:/moganshan/afs_a/lai/pretrained/ \
    -e "ssh -p 10322"
```

### A100 环境初始化参考流程（SSH 登录后执行）
```bash
# 切换到个人账号（密码见 A100_login.txt）
su lai
cd /moganshan/afs_a/lai

# 激活或创建 conda 环境
conda create -n evo-rl python=3.10 -y  # 若不存在
conda activate evo-rl

# 安装 Evo-RL 包
cd /moganshan/afs_a/lai/Evo-RL
pip install -e .
```

### A100 与 4090 脚本的关键差异（在 4090.sh 基础上改这几行）
- `WORK_DIR="/moganshan/afs_a/lai/Evo-RL"` （硬编码，非动态 dirname）
- `NUM_GPUS=4`
- `CUDA_VISIBLE_DEVICES=0,1,2,3`
- `OUTPUT_DIR="${WORK_DIR}/outputs/pen_round1_A100"`
- 注释标题改为 "4x A100 (80GB)"

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 训练脚本参考
- `Evo-RL/scripts/train_pen_4090.sh` — **A100 脚本的唯一直接模板**（路径约定、参数结构、CUDA/accelerate launch 写法、3 阶段逻辑全复用）
- `Evo-RL/scripts/smoke_test_4090.sh` — smoke test 参考（验证逻辑）

> ⚠️ **不要参考 `train_pen_npu.sh`**：该脚本使用华为 NPU 专有环境变量（`ASCEND_RT_VISIBLE_DEVICES`）、`.venv` 激活方式和 NPU 特有路径，与 NVIDIA GPU（N 卡）训练不兼容。A100 是 NVIDIA 卡，完全沿用 4090 脚本的 CUDA/accelerate 写法。

### 项目配置
- `Evo-RL/pyproject.toml` — pip install -e . 的依赖来源
- `Evo-RL/docs/reproduction_guide.md` — 完整复现顺序（步骤 4-7 为 A100 端操作）

### 安全
- `Evo-RL/A100_login.txt` — 连接信息（仅本地查阅，不写入规划/脚本）

</canonical_refs>

<code_context>
## Existing Code Insights

### 可直接复用的脚本结构
`train_pen_4090.sh` 结构完整，只需修改路径/GPU 配置即可：
- `set -euo pipefail` + 启动前检查（CUDA 可用性 + 权重目录 + 数据集）
- 三阶段 `eval ${LAUNCH}` 调用（lerobot-value-train → lerobot-value-infer → lerobot-train）
- 注释详细，直接作为 A100 版模板

### 预训练权重本地路径（已确认）
```
/media/wzt/jzh/Evo-RL/pretrained/
├── gemma-3-270m/           (549MB)
├── models--google--paligemma-3b-pt-224/  (21MB, tokenizer)
├── pi05_base/              (14GB)
└── siglip-so400m-patch14-384/  (3.3GB)
```

### 旧的 ENV 计划（已搁置但可参考）
`.planning/phases/01-environment/01-01-PLAN.md.deferred` — 包含 rsync_to_a100.sh 和 download_weights.sh 的详细实现规范，可直接参考用于本 Phase 的 rsync 脚本设计。

</code_context>

<deferred>
## Deferred Ideas

- 数据集 rsync 到 A100（fold_cloth / Kai0 在 Phase 2 或 Phase 3 前处理）
- NPU 训练脚本完善（train_pen_npu.sh 已存在，后续按需补充）
- wandb API key 配置（训练时交互式配置）
- 多用户 conda 环境共享（仅当团队扩展时考虑）
- A100 上的 smoke_test_A100.sh（可选，Claude 自行决定是否创建）

</deferred>

---

*Phase: 02-training-pipeline*
*Context gathered: 2026-03-25 via /gsd:discuss-phase*
