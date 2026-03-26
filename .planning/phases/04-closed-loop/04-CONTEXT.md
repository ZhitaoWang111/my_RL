# Phase 4: Closed Loop - Context

**Gathered:** 2026-03-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 4 交付两件事：
1. **async_inference 推理链路梳理与 fold_cloth 适配** — 在本机 4090 上通过 gRPC 多线程架构（PolicyServer + RobotClient）运行 fold_cloth 双臂推理
2. **启动脚本** — 新建 run_eval_fold_cloth.sh，预填 fold_cloth 相机、checkpoint、双臂参数

**不在本 Phase 范围内：**
- eval_bipiper.py（单进程同步推理链路）— 不使用
- A100 / NPU 推理（仅 4090 本机）
- 数据采集 / rollout 录制 / Round 2 迭代 — 后续 phase
- 推理性能调优（fps / latency 优化）

</domain>

<decisions>
## Implementation Decisions

### 推理架构
- **D-01:** 仅使用 async_inference（gRPC 多线程 server/client），不使用 eval_bipiper.py（单进程同步）
- **D-02:** 推理在本机 4090 上执行，PolicyServer 和 RobotClient 在同一机器上启动

### fold_cloth 任务适配
- **D-03:** action 全 14 维，双臂均使用 policy 输出（前 7 维左臂，后 7 维右臂），不截断
- **D-04:** STATE_SLICE="" / ACTION_SLICE=""，与训练时一致（全 14 维）
- **D-05:** 相机配置复用 run_eval.sh 中的 3 个 RealSense 相机：
  - 左腕 wrist_left: serial 244622300342
  - 右腕 wrist_right: serial 231122302328
  - 顶部 top: serial 231122301462
- **D-06:** 相机名映射：机器人物理相机名 → 训练时 dataset feature 名（left_wrist_left / left_top / right_wrist_right），通过 RobotClient 的 rename_map 配置

### 启动方式
- **D-07:** 新建 `Evo-RL/scripts/run_eval_fold_cloth.sh` 启动脚本，包含 server + client 两条启动命令
- **D-08:** checkpoint 路径：NPU 训练完成后从服务器 rsync 回本地，指向 `outputs/cloth_round1/pi05_train/checkpoints/last/pretrained_model`
- **D-09:** policy_device="cuda:0"，client_device="cpu"

### Claude's Discretion
- server 端 FPS / inference_latency / obs_queue_timeout 的默认值是否需要调整
- actions_per_chunk 取多少（默认跟随 policy chunk_size）
- aggregate_fn 选择（默认 weighted_average）
- chunk_size_threshold 值（默认 0.5）

</decisions>

<specifics>
## Specific Ideas

### async_inference 启动命令模板

**Terminal 1 — PolicyServer:**
```bash
python -m lerobot.async_inference.policy_server \
    --host=127.0.0.1 \
    --port=8080 \
    --fps=30 \
    --inference_latency=0.033 \
    --obs_queue_timeout=2
```

**Terminal 2 — RobotClient:**
```bash
python src/lerobot/async_inference/robot_client.py \
    --robot.type=bi_piper_follower \
    --robot.left_arm_config.port=can0 \
    --robot.right_arm_config.port=can2 \
    --task="fold cloth" \
    --server_address=127.0.0.1:8080 \
    --policy_type=pi05 \
    --pretrained_name_or_path=outputs/cloth_round1/pi05_train/checkpoints/last/pretrained_model \
    --policy_device=cuda:0 \
    --client_device=cpu \
    --actions_per_chunk=50 \
    --chunk_size_threshold=0.5 \
    --aggregate_fn_name=weighted_average
```

### state_slice 自动检测
PolicyServer 加载 checkpoint 时，自动从 `train_config.json` 读取 `train_state_slice`。fold_cloth 训练时 STATE_SLICE=""，因此 train_config.json 中该字段为空，server 使用全维度。无需手动配置。

### 相机名映射
训练时 dataset 的 feature key 是 `observation.images.left_wrist_left` 等，但机器人 observation_features 的 key 格式可能不同。RemotePolicyConfig 的 rename_map 用于映射。需确认 BiPiperFollower 的 observation_features key 命名规则与 dataset feature key 的差异。

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning.**

- `Evo-RL/src/lerobot/async_inference/policy_server.py` — PolicyServer gRPC 服务端，obs 入队 + 推理 + action 返回
- `Evo-RL/src/lerobot/async_inference/robot_client.py` — RobotClient gRPC 客户端，双线程控制循环 + action 队列管理
- `Evo-RL/src/lerobot/async_inference/helpers.py` — 数据类型定义（TimedAction/TimedObservation/RemotePolicyConfig）、obs→tensor 转换
- `Evo-RL/src/lerobot/async_inference/configs.py` — PolicyServerConfig / RobotClientConfig / aggregate 函数注册
- `Evo-RL/src/lerobot/async_inference/constants.py` — SUPPORTED_POLICIES / SUPPORTED_ROBOTS / 默认 FPS
- `Evo-RL/scripts/run_eval.sh` — 现有推理启动脚本（pen 任务），相机序列号和 CAN 端口配置参考
- `Evo-RL/src/lerobot/robots/bi_piper_follower/` — BiPiperFollower 机器人接口，observation_features 和 action_features 定义

</canonical_refs>

<code_context>
## Existing Code Insights

### async_inference 架构
- **PolicyServer**: gRPC 服务端，ThreadPoolExecutor(4 workers)，observation_queue(maxsize=1) 只保留最新 obs
- **RobotClient**: 双线程（control_loop + receive_actions），Barrier 同步启动，action_queue 无限大小
- **Action 聚合**: 新旧 chunk 重叠 timestep 通过 aggregate_fn 加权融合（默认 0.3*old + 0.7*new）
- **chunk_size_threshold=0.5**: 队列剩余 < 50% 时触发新一轮推理，实现流水线化
- **must_go 机制**: 队列为空时强制 obs 进入推理，防止初始死锁

### 已有热键支持
- r = 暂停推理，清空 action 队列，发送安全位姿（LEFT_ARM_SAFE_POSE）
- c = 恢复推理，设置 must_go 触发新 chunk
- 热键通过 pynput 后台线程监听

### state_slice 自动加载
- PolicyServer.SendPolicyInstructions() 从 checkpoint 目录的 train_config.json 读取 train_state_slice
- fold_cloth 训练无 slice → train_config.json 中为空 → 使用全 14 维，无需额外配置

### Pi05 已在 SUPPORTED_POLICIES
- constants.py 中 SUPPORTED_POLICIES 包含 "pi05"
- bi_piper_follower 已在 SUPPORTED_ROBOTS

</code_context>

<deferred>
## Deferred Ideas

- **数据采集集成** — 推理 + 录制 rollout 数据用于 Round 2 迭代，需与 lerobot-human-inloop-record 集成
- **NPU → CUDA checkpoint 兼容性验证** — 需确认 PyTorch 权重跨设备加载无问题
- **推理性能调优** — FPS / inference_latency / actions_per_chunk 参数调优
- **eval_bipiper.py fold_cloth 适配** — 如果需要单进程方案作为备选

</deferred>

---

*Phase: 04-closed-loop*
*Context gathered: 2026-03-26 via /gsd:discuss-phase*
