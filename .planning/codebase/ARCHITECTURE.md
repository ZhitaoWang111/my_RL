# Architecture

**Analysis Date:** 2026-03-24

## Pattern Overview

**Overall:** Multi-layer modular robotics framework with composable data processors, pluggable policy modules, and value-driven offline RL pipeline.

**Key Characteristics:**
- Plugin-based policy architecture (factory pattern for dynamic policy instantiation)
- Data processing pipeline with composable processor steps
- Separation of concerns: data collection, processing, training, inference
- Multi-robot support through standardized Robot and Teleoperator interfaces
- Offline RL loop: value training → advantage inference (ACP) → policy training with conditioned prompts

## Layers

**Hardware Abstraction Layer:**
- Purpose: Standardize interaction with physical robots and teleoperation devices
- Location: `src/lerobot/robots/`, `src/lerobot/teleoperators/`, `src/lerobot/motors/`
- Contains: Robot base class, motor drivers (Dynamixel, Feetech, Damiao/CAN), camera interfaces
- Depends on: Hardware SDKs (piper_sdk, feetech-servo-sdk, dynamixel-sdk, pyserial)
- Used by: Data collection scripts, hardware setup utilities

**Data Processing Pipeline Layer:**
- Purpose: Transform raw robot observations/actions through composable processor steps
- Location: `src/lerobot/processor/`
- Contains: Base pipeline classes, specialized processor steps (normalization, device placement, batch conversion, image preprocessing, ACP hooks)
- Depends on: Core transition types (RobotObservation, RobotAction, PolicyAction)
- Used by: Data collection loop, inference, training

**Dataset Management Layer:**
- Purpose: Load, store, and manage datasets with version control and metadata
- Location: `src/lerobot/datasets/`
- Contains: LeRobotDataset (Hugging Face datasets integration), stats computation, video encoding/decoding
- Depends on: Hugging Face datasets library, PyArrow, OpenCV
- Used by: Training scripts, evaluation, offline RL workflows

**Policy Architecture Layer:**
- Purpose: Pluggable policy models with configurable preprocessing/postprocessing
- Location: `src/lerobot/policies/` (act/, diffusion/, pi0/, pi05/, sac/, smolvla/, tdmpc/, vqbet/, etc.)
- Contains: Policy classes, configuration objects, model architectures, processor definitions
- Depends on: PyTorch, transformers, diffusers, policy-specific dependencies
- Used by: Training, inference, policy selection via factory

**Value Function Layer (RL-Specific):**
- Purpose: Train and infer value functions to guide policy learning via advantage conditioning
- Location: `src/lerobot/values/pistar06/`
- Contains: Pi*0.6 value model (SigLIP vision encoder + Gemma LM + MLP value head)
- Depends on: Transformers (SigLIP, Gemma), PyTorch
- Used by: RL training pipeline (value-train → value-infer → policy-train with ACP)

**RL Pipeline Layer:**
- Purpose: Coordinate value training, advantage inference (ACP), and policy training
- Location: `src/lerobot/scripts/lerobot_value_train.py`, `lerobot_value_infer.py`, `lerobot_train.py`, `src/lerobot/rl/`
- Contains: Training entry points, ACP hooks, wandb integration, distributed training utilities
- Depends on: All lower layers
- Used by: End users, experiment orchestration

**Supporting Infrastructure:**
- Utilities: `src/lerobot/utils/` (constants, logging, device detection, random seeds, training utilities)
- Async Inference: `src/lerobot/async_inference/` (gRPC policy server, robot client for distributed deployment)
- Transports: `src/lerobot/transport/` (gRPC protobuf services)
- Configs: `src/lerobot/configs/` (training config, policy configs, environment configs)

## Data Flow

**Data Collection (Recording) Flow:**

1. **Hardware State Acquisition:**
   - `robot.get_observation()` → raw joint angles + camera images (30 Hz loop)
   - `teleop.get_action()` → leader joint angles (or keyboard/gamepad input)

2. **Observation Processing:**
   - Robot observation → `robot_observation_processor` (identity by default)
   - Output: `RobotObservation` dict with state and images

3. **Action Processing:**
   - Teleop action → `teleop_action_processor` (identity) → `RobotAction` dict
   - Robot action → optional delta/control transformations via `robot_action_processor`

4. **Frame Assembly & Recording:**
   - `build_dataset_frame()` combines obs, action, timestamps, task metadata
   - Numeric data → episode buffer (in-memory list)
   - Images → `AsyncImageWriter` (queued, encoded as MP4/AV1, written async)

5. **Episode Finalization:**
   - On reset or timeout: write episode buffer to Parquet (state, action, complementary_info)
   - Metadata: episode_index, task_index, episode_success flag

6. **Optional: Human-in-the-Loop (HIL) Recording:**
   - Policy deployed during collection: `policy(obs) → action_pred`
   - `intervention_detector` monitors for human override
   - Records: `is_intervention`, `policy_action`, `collector_policy_id`

**Value Inference (ACP) Flow:**

1. **Dataset Loading:**
   - `LeRobotDataset` loads full episodes + computed stats

2. **Value Model Inference:**
   - For each frame: vision_encoder(image) + language_model(task_text) → value distribution
   - Output: return-to-go estimate (range [-1.0, 0.0]) per frame

3. **Advantage & ACP Indicator:**
   - Compute advantage = V(s) - min_V (relative to episode minimum)
   - Binarize top 30% as indicator=1 (high-quality), rest as indicator=0

4. **Prompt Injection:**
   - Store in dataset as `complementary_info.acp_indicator_<TAG>`
   - Policy training reads this flag → modifies task prompt: append "\nAdvantage: positive" or drop label (30% dropout)

**Policy Training Flow:**

1. **Config & Data Setup:**
   - Load dataset with ACP indicators
   - Initialize policy (e.g., PI0.5 PaliGemma + Action Expert ~3.6B params)

2. **Preprocessing Pipeline:**
   - Observation (images + state) → image normalization, state discretization (0-255)
   - State tokens → embedded in task prompt: "Task: fold cloth, State: 128 95 203 ...; Action:"
   - If ACP enabled: append advantage label with 0.3 dropout
   - Tokenize with PaliGemma tokenizer (max_length=200)

3. **Training Loop:**
   - Sample batch (B=32, chunk_size=50 frames)
   - Forward: embed observations → predict action sequence (B, 50, 32)
   - Loss: L2 on flow-matching denoise (10 steps) + optional advantage-weighted sampling
   - Backward, optimizer step (AdamW, lr=1e-4, gradient ckpt)

4. **Inference:**
   - x_0 ~ N(0,1) → 10 denoising steps → continuous action (B, 50, 32)
   - Clip to actual action_dim, unnormalize (QUANTILES), send to robot

**State Management:**

- **Training State:**
  - Optimizer params (per-layer LR), scheduler state → `TRAINING_STATE_DIR/optimizer_param_groups.json`
  - Step counter → `training_step.json`
  - Saved on checkpoint, loaded to resume

- **Model Checkpoints:**
  - Full model weights → `CHECKPOINTS_DIR/{step}/pretrained_model/`
  - Symlink `LAST_CHECKPOINT_LINK` for convenience

- **Environment State:**
  - Dataset cached locally after first download (Hugging Face hub)
  - Calibration files → `~/.cache/huggingface/lerobot/calibration/<robot_type>/<id>.json`
  - Logs → `logs/` directory with policy_server & robot_client logs

## Key Abstractions

**Robot Interface:**
- Purpose: Abstracts different robotic platforms (SO101, PiPER, Reachy2, etc.)
- Examples: `src/lerobot/robots/bi_so_follower/`, `src/lerobot/robots/bi_piper_follower/`
- Pattern: Subclass `Robot` base class, implement `get_observation()`, `send_action()`, connect/disconnect lifecycle
- Provides: `observation_features`, `action_space` definitions; calibration management

**Teleoperator Interface:**
- Purpose: Abstracts input devices (leader arms, keyboards, gamepads, phones)
- Examples: `src/lerobot/teleoperators/bi_so_leader/`, `src/lerobot/teleoperators/keyboard/`, `src/lerobot/teleoperators/gamepad/`
- Pattern: Subclass `Teleoperator`, implement `get_action()`, context manager protocol
- Provides: Action space mapping, event handling

**Processor Pipeline:**
- Purpose: Composable transformation of observations/actions through serializable steps
- Examples: `src/lerobot/processor/normalize_processor.py`, `src/lerobot/processor/device_processor.py`, `src/lerobot/processor/tokenizer_processor.py`
- Pattern: Each step implements `__call__(transition_dict) → transition_dict`, steps chain via composition
- Provides: Serialization to JSON config, loading from pretrained checkpoint

**Policy Factory:**
- Purpose: Dynamically instantiate policy models without hard-coding dependencies
- Location: `src/lerobot/policies/factory.py`
- Pattern: `get_policy_class(name: str)` → dynamic import + class retrieval; `make_policy()` constructs full pipeline
- Provides: Extensibility: add new policy type → register in factory, no core code changes

**Configuration System:**
- Purpose: Centralized, type-safe config for training/inference
- Examples: `src/lerobot/configs/train.py`, `src/lerobot/configs/value_train.py`
- Pattern: Dataclass-based (draccus), CLI argument mapping, config merging
- Provides: Full experiment reproducibility, checkpoint resume capability

## Entry Points

**Data Collection:**
- Location: `src/lerobot/scripts/lerobot_record.py`
- Triggers: CLI: `lerobot-record --config_path=configs/record_fold_cloth.yaml`
- Responsibilities: Spawn robot + teleop, run 30 Hz recording loop, save episodes to dataset

**Human-in-the-Loop Recording:**
- Location: `src/lerobot/scripts/lerobot_human_inloop_record.py`
- Triggers: CLI with optional `--policy.path=<checkpoint>`, `--resume=true`
- Responsibilities: Deploy policy, detect interventions, merge policy + human actions

**Value Function Training:**
- Location: `src/lerobot/scripts/lerobot_value_train.py`
- Triggers: CLI: `lerobot-value-train --dataset_repo_id=<path> --value.type=pistar06 --value.model_name_or_path=...`
- Responsibilities: Load dataset, create value model, train, save checkpoint to wandb/local

**Value Inference + ACP Labeling:**
- Location: `src/lerobot/scripts/lerobot_value_infer.py`
- Triggers: CLI: `lerobot-value-infer --dataset_repo_id=<path> --value.path=<checkpoint> --acp.enable=true`
- Responsibilities: Compute value per frame, binarize advantage, inject labels into dataset, save augmented dataset

**Policy Training:**
- Location: `src/lerobot/scripts/lerobot_train.py`
- Triggers: CLI: `lerobot-train --dataset_repo_id=<path> --policy.type=pi05 --policy.path=<pretrained> --acp.enable=true`
- Responsibilities: Load dataset with ACP indicators, train policy model, log to wandb, save checkpoint

**Policy Evaluation:**
- Location: `src/lerobot/scripts/lerobot_eval.py`
- Triggers: CLI: `lerobot-eval --policy.path=<checkpoint> --dataset_repo_id=<path> --eval.num_episodes=10`
- Responsibilities: Roll out policy on real robot or sim env, compute success rate

**Teleoperation (Hardware Test):**
- Location: `src/lerobot/scripts/lerobot_teleoperate.py`
- Triggers: CLI: `lerobot-teleoperate --robot.type=bi_piper_follower --teleop.type=bi_piper_leader`
- Responsibilities: Connect robot + teleop, run live control loop (no recording)

## Error Handling

**Strategy:** Layered approach with specific exceptions and graceful degradation

**Patterns:**
- Hardware disconnection → context manager `__exit__` ensures cleanup; retry logic in recording loop
- Missing calibration → load from fallback or skip (feetech motors); PiPER uses absolute encoders (no calibration needed)
- Device placement errors → auto-detect CUDA/MPS/CPU via `get_safe_torch_device()`, notify user
- Config validation → draccus dataclass validation catches missing required fields early
- Dataset loading → Hugging Face snapshot_download with retry; falls back to local cache
- Model loading → transformers `from_pretrained` with timeout; graceful skip if vision encoder unavailable

## Cross-Cutting Concerns

**Logging:**
- Approach: Python `logging` module with `src/lerobot/utils/logging_utils.py` helpers
- Per-module loggers initialized at module level
- Wandb integration in training scripts via `src/lerobot/rl/wandb_utils.py` (optional, respects `--wandb.enable` flag)

**Validation:**
- Observation/action schema: Checked against `observation_features` / `action_space` at runtime
- Feature name consistency: `_validate_feature_names()` in dataset loading
- Configuration: Draccus dataclass validation on instantiation

**Authentication:**
- Hugging Face token: Read from `~/.huggingface/token` or `HF_TOKEN` env var
- Robot hardware credentials: None required (serial ports direct, CAN bus native)
- Dataset access: Repo visibility (public/private) enforced by Hugging Face Hub

**Random Seeding:**
- Approach: Centralized `set_seed()` in `src/lerobot/utils/random_utils.py`
- Sets: `random.seed()`, `np.random.seed()`, `torch.manual_seed()`, torch CUDA seed, cuDNN settings
- Called early in training/eval scripts to ensure reproducibility

