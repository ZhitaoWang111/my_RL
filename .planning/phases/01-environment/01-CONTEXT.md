# Phase 1: Environment - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 1 交付：开发者可在任意目标机器（RTX 4090 本地机 / A100 服务器）上一步重建训练环境并验证就绪。

本 Phase 聚焦于：
- Evo-RL 代码从本地迁移到 A100 共享存储
- A100 上重建 conda 环境（`evo-rl`，Python 3.10）
- 预训练权重下载脚本（本地下载，后续 rsync 到 A100）
- 环境验证命令（10 秒内确认 CUDA、依赖、权重就绪）

**不在本 Phase 范围内：** 数据集迁移、训练脚本执行、PiPER 硬件配置。

</domain>

<decisions>
## Implementation Decisions

### A100 代码部署

- **D-01:** 代码目标路径为 `/moganshan/afs_a/lai/Evo-RL`（共享 NAS 存储）
- **D-02:** 传输方式为从本地机器 `rsync` 到 A100，不使用 git clone（保留本地修改）
- **D-03:** 连接方式：`ssh moganshan@180.184.148.169 -p 10322`，共享存储用户路径 `/moganshan/afs_a/lai`
- **D-04:** 注意：不在规划文档中存储任何账号密码（安全原则）

### A100 conda 环境

- **D-05:** 在 A100 上重新执行 `pip install -e .` 建立 `evo-rl` 环境，不从本地打包迁移
- **D-06:** 参考 `Evo-RL/pyproject.toml` 和 `requirements-ubuntu.txt` 安装依赖
- **D-07:** 版本漂移（transformers 4.53.3 vs 4.57.1, wandb 0.24.2 vs 0.21.4, accelerate 1.13.0 vs 1.11.0）不强制同步，仅文档记录

### 预训练权重

- **D-08:** 权重暂不上传到 A100；本地先下载完整权重，后续单独 rsync
- **D-09:** 权重下载脚本（`download_weights.sh`）在本地和 A100 均可使用
- **D-10:** 权重在 A100 上的目标路径：`/moganshan/afs_a/lai/pretrained/`（共享存储，复用）
- **D-11:** 支持 `HF_ENDPOINT=https://hf-mirror.com` 镜像选项（以备 A100 直连 HF 受限）

### 数据集

- **D-12:** 本 Phase 不迁移数据集，pen 数据集 (`/home/wzt/wzt/data/pen`) 后续单独处理

### 本地机（RTX 4090）

- **D-13:** 本地 `evo-rl` 环境已就绪，Phase 1 对本地主要交付权重下载脚本和验证脚本

### Claude's Discretion

- rsync 命令的具体参数选择（`--exclude`、`--progress` 等）
- 验证脚本的输出格式（彩色 vs 纯文本）
- setup_guide.md 文档结构和章节顺序

</decisions>

<specifics>
## Specific Ideas

- rsync 命令格式参考：
  ```bash
  rsync -avz --progress --exclude='.git' --exclude='outputs/' --exclude='pretrained/' \
    /home/wzt/wzt/mycode/my_RL/Evo-RL/ \
    moganshan@180.184.148.169:/moganshan/afs_a/lai/Evo-RL/ \
    -e "ssh -p 10322"
  ```
- 权重 rsync 命令（本地下载完毕后执行）：
  ```bash
  rsync -avz --progress \
    /home/wzt/wzt/mycode/my_RL/Evo-RL/pretrained/ \
    moganshan@180.184.148.169:/moganshan/afs_a/lai/pretrained/ \
    -e "ssh -p 10322"
  ```
- A100 上切换到 lai 账号共享存储：`su lai` 或直接访问 `/moganshan/afs_a/lai`
- 安全提醒：所有账号密码通过 1Password 或团队密码管理工具共享，不写入代码仓库

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 项目配置

- `Evo-RL/pyproject.toml` — Python 包依赖定义
- `Evo-RL/requirements-ubuntu.txt` — 锁定版本依赖（Ubuntu/CUDA 环境）
- `Evo-RL/scripts/train_pen_4090.sh` — 参考脚本（包含路径约定）

### 研究结论

- `.planning/phases/01-environment/01-RESEARCH.md` — 已确认的包版本、权重 HF ID、版本漂移详情

### 项目文档

- `Evo-RL/docs/reproduction_guide.md` — pi05_base tokenizer 路径修复说明

No external ADRs — requirements fully captured in decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### 可复用资产

- `Evo-RL/scripts/train_pen_4090.sh` — 路径约定参考（`PRETRAINED_DIR`, `DATA_DIR`, `OUTPUT_DIR`）
- `Evo-RL/pretrained/paligemma-3b-pt-224/` — tokenizer 文件已在本地
- 现有 `evo-rl` conda env — 可用 `conda env export` 生成 `environment.yml` 作为参考

### 集成点

- `Evo-RL/src/lerobot/` — editable install 入口，`pip install -e .` 后 CLI 命令可用
- `PRETRAINED_DIR` 变量在所有训练脚本中使用，A100 上改为 `/moganshan/afs_a/lai/pretrained`

</code_context>

<deferred>
## Deferred Ideas

- 数据集迁移（pen dataset rsync）— Phase 2 前处理
- wandb API key 配置 — 训练时再处理
- gRPC 异步推理服务器部署 — Phase 4 内容
- 多用户 conda 环境共享配置 — 仅当团队扩展时考虑

</deferred>

---

*Phase: 01-environment*
*Context gathered: 2026-03-25 via /gsd:discuss-phase*
