<!-- GSD:project-start source:PROJECT.md -->
## Project

**Evo-RL**

Evo-RL 是基于 LeRobot 构建的真实世界 offline-to-online 强化学习框架，支持 AgileX PiPER 等机械臂平台。核心流程：价值函数训练（Pi*0.6）→ ACP 标注 → 策略训练（Pi0.5），通过 advantage-conditioned prompt 实现轨迹质量筛选。本仓库是团队主要开发仓库，目标是覆盖从数据采集到闭环 rollout 的完整 RL 训练流水线。

**Core Value:** **完整跑通 3 步训练流水线**（conda 环境 → 权重下载 → value-train → value-infer → policy-train），在真机上完成一轮 RL 迭代。

### Constraints

- **Tech Stack**: Python 3.10, PyTorch 2.7.1, Transformers 4.57.1, Accelerate 1.11.0 — 不升级上游版本
- **Hardware**: 训练脚本需覆盖 A100 / 4090 / NPU 三类，batch size 按设备显存调整
- **Data**: 数据集格式遵循 LeRobot 规范（parquet + video），ACP 字段写入 `complementary_info.*`
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- Python 3.10+ - Core language for all robotic simulation, policy training, and control code
## Runtime
- Python 3.10 (minimum requirement)
- pip/setuptools - Standard Python package management
- Lockfile: `requirements-ubuntu.txt` and `requirements-macos.txt` (compiled from requirements.in)
## Frameworks & Core Libraries
- PyTorch 2.7.1 - Neural network training and inference for policies
- TorchVision 0.22.1 - Computer vision utilities for image processing
- Transformers 4.57.1 - Pre-trained language/vision models for policy architectures
- Diffusers 0.35.2 - Diffusion-based policy implementations
- Gymnasium 1.2.1 - Environment API for RL training
- gym-aloha 0.1.3 - ALOHA robot simulation environment
- gym-pusht 0.1.6 - PushT task simulation
- gym-hil 0.1.13 - Human-in-the-loop training environment
- Piper SDK 0.6.1+ - Piper robot hardware control
- Reachy2 SDK 1.0.14 - Reachy2 robot hardware interface
- DynamixelSDK 3.8.4 - Dynamixel motor control
- Feetech Servo SDK 1.0.0 - Feetech motor control
- pin 3.4.0 & placo 0.9.14 - Robot kinematics and inverse kinematics (PyPinocchio)
- HuggingFace Hub 0.35.3 - Model and dataset downloading/uploading
- Datasets 4.1.1 - HF dataset loading and processing
- Accelerate 1.11.0 - Multi-GPU/TPU training utilities
- Weights & Biases (wandb) 0.21.4 - Experiment logging and tracking
- Rerun SDK 0.26.1 - Real-time 3D visualization for robotics debugging
- Tensorboard 2.20.0 - Training metrics visualization
- Draccus 0.10.0 - Dataclass-based configuration management
- Hydra Core 1.3.2 - Configuration composition framework
- OmegaConf 2.3.0 - Configuration object library
- PyYAML 6.0.3 - YAML configuration parsing
- OpenCV Python Headless 4.12.0.88 - Image processing without GUI
- Pillow 12.0.0 - Image manipulation
- av 15.1.0 - Audio/video codec handling
- TorchCodec 0.5 - Video frame decoding
- ImageIO + ffmpeg 2.37.0 - Media file I/O
- NumPy 2.2.6 - Numerical computing
- Pandas 2.3.3 - Data manipulation and analysis
- einops 0.8.1 - Tensor operation abstractions
- Scikit-image 0.25.2 - Image processing algorithms
- Decord 0.6.0 - Video decoding for training data
- SciPy 1.15.3 - Scientific computing routines
- Matplotlib 3.10.7 - Plotting and visualization
- dm-control 1.0.34 - DeepMind Control Suite environments
- MuJoCo 3.3.7 - Physics simulation engine
- CasADi 3.6.0 - Symbolic math and optimization
- pytest 8.4.2 - Test framework
- pytest-cov 7.0.0 - Coverage reporting
- pytest-timeout 2.4.0 - Test timeout management
- Ruff 0.14.1 - Fast Python linter and formatter
- Pre-commit 4.3.0 - Git hooks framework
- MyPy 1.19.1 - Static type checking
- Bandit 1.8.6 - Security linting
- Typos 1.38.1 - Spell checking
- pySerial 3.5 - Serial port communication
- PyInput 1.8.1 - Keyboard/mouse input
- PyZMQ 27.1.0 - Zero Message Queue for distributed control
- python-can 4.2.0 - CAN bus communication
- gRPC 1.73.1 - RPC framework for async operations
- termcolor 3.1.0 - Colored terminal output
- tqdm 4.67.1 - Progress bars
- jsonlines 4.0.0 - JSONL file handling
- deepdiff 8.6.1 - Deep comparison utilities
- packaging 25.0 - Version parsing
- peft 0.17.1 - Parameter-efficient fine-tuning
## Configuration Files
- `pyproject.toml` - Project metadata and dependencies
- `setup.py` - Setup script for editable installation
- `.pre-commit-config.yaml` - Git hooks for code quality
- `pyproject.toml` [tool.ruff] - Linting and formatting rules
- `pyproject.toml` [tool.mypy] - Type checking configuration
- `requirements-ubuntu.txt` - Complete Ubuntu dependency lock file
- `requirements-macos.txt` - Complete macOS dependency lock file
- `requirements.in` - Base requirements for compilation
## Platform Requirements
- Python 3.10+
- pip + setuptools
- Git
- Pre-commit hooks (optional but recommended)
- GPU support: CUDA 12 (nvidia packages included)
- macOS: Native PyObjC support for system integration
- Linux: Standard x86_64 or ARM64 support
- Piper robots (via piper_sdk)
- Reachy2 robots (via reachy2_sdk)
- Dynamixel motors (via dynamixel-sdk)
- Feetech motors (via feetech-servo-sdk)
- Intel RealSense cameras (via pyrealsense2)
- HEBI robotics (via hebi-py)
## Key Dependencies by Function
- torch, torchvision, transformers, accelerate, wandb, rerun-sdk
- datasets, huggingface-hub, imageio, av, torchcodec, decord
- gymnasium, gym-aloha, gym-pusht, gym-hil, mujoco, dm-control
- piper_sdk, reachy2_sdk, dynamixel-sdk, feetech-servo-sdk, pyserial, pyzmq
- matplotlib, rerun-sdk, meshcat
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Naming Patterns
- Lowercase with underscores: `motors_bus.py`, `lerobot_dataset.py`
- Configuration files: `configs.py`, `parser.py`
- Module files grouped by functionality: `camera.py`, `robot.py`, `policy.py`
- Lowercase with underscores: `get_address()`, `sync_read()`, `create_initial_features()`
- Private functions prefixed with underscore: `_serialize_data()`, `_encode_video_worker()`, `_flush_metadata_buffer()`
- Abstract methods marked with `@abc.abstractmethod` decorator
- Lowercase with underscores for local and module-level variables: `ctrl_table`, `model_ctrl_table`
- Type aliases use PascalCase: `NameOrID`, `Value`, `NDArray`
- Constants in UPPERCASE: `DEFAULT_CHUNK_SIZE`, `DEFAULT_VIDEO_FILE_SIZE_IN_MB`
- Classes use PascalCase: `Camera`, `MotorsBusBase`, `LeRobotDataset`
- Enum classes inherit from `str` and `Enum`: `MotorNormMode(str, Enum)`
- Dataclass fields use lowercase: `@dataclass class Motor: id: int`
## Code Style
- Tool: Ruff (configured in `pyproject.toml`)
- Line length: 110 characters
- Quote style: Double quotes (`"string"`)
- Indent style: 4 spaces
- Skip magic trailing comma: False
- Tool: Ruff (astral-sh/ruff-pre-commit v0.14.1)
- Selected rules: E, W, F, I, B, C4, T20, N, UP, SIM
- Ignored rules: E501 (line too long), T201/T203 (print statements), B008 (function call in defaults)
- Per-file ignores: `__init__.py` ignores F401, F403 (unused imports)
- Special handling: `src/lerobot/policies/wall_x/**` has suppressed rules for original Qwen code
- File size check: 1024 KB limit
- Debug statement detection
- Merge conflict detection
- YAML/TOML validation
- End-of-file fixer (excluding URDF assets)
- Trailing whitespace removal
- Typo detection via typos hook
- Security scanning via bandit and gitleaks
## Import Organization
- Use `from __future__ import annotations` at top of file for forward references
- Combine relative imports: `from .configs import CameraConfig`
- Type hints after line: `from typing import Any, Protocol, TypeAlias, TypeVar`
- Known first-party: `lerobot` (configured in ruff.lint.isort)
- Import directly: `from lerobot.motors.motors_bus import Motor`
- No path aliasing symbols used
## Error Handling
- Location: `src/lerobot/utils/errors.py`
- Base classes: Inherit from standard exceptions (e.g., `ConnectionError`)
- Pattern:
- Use descriptive messages with context: `raise KeyError(f"Address for '{data_name}' not found in {model} control table.")`
- Include variable values using f-strings: `raise IndexError(f"Episode index {ep_index} out of range. Episodes: {len(self.episodes)}")`
- Specific exception types for specific conditions: `KeyError` for missing keys, `NotImplementedError` for unsupported operations
- For NotImplementedError, include what operation is not supported and why
- Try/except blocks catch specific exceptions first
- Use `except (FileNotFoundError, NotADirectoryError)` for multiple related exceptions
- Suppress expected warnings with `# nosec B110` comment for security scanner when catching bare `Exception`
- Cleanup in finally or use context managers
## Logging
- `logger.debug()`: Fine-grained diagnostic information (timing, detailed state)
- `logger.info()`: Confirmation that things are working (connection status, initialization)
- `logger.warning()`: Something unexpected happened (fallback actions, deprecated usage)
- `logger.error()`: Serious problem (computation failures, convergence errors)
- `logger.info(f"{self} connected.")` - Connection status
- `logger.warning(f"Device '{self.device}' is not available. Switching to '{auto_device}'.")` - Fallback action
- `logger.error(f"{CONFIG_NAME} not found in {Path(model_id).resolve()}")` - File not found
- `logger.debug(f"{self} read action: {dt_ms:.1f}ms")` - Timing information
## Comments
- Explain non-obvious logic or assumptions
- Document workarounds and TODOs with issue references
- Mark suppressed linting rules with explanation
- Use triple-quoted strings for docstrings
- Sections: `Args:`, `Returns:`, `Raises:` (optional)
- Type hints in function signatures, not in docstrings
- Example:
## Function Design
- Keep functions focused and reasonably sized
- Extract helper functions for repeated patterns
- Private methods prefixed with `_` for internal implementation details
- Use keyword-only arguments after `*` for clarity: `def save(..., allow_patterns: str | None = None, *, force_cache_sync: bool = False)`
- Type hints required for all parameters and return values
- Default values use `None` or sensible type-specific defaults
- Type hints required
- Return tuples for multiple values: `tuple[int, int]`
- Use `None` explicitly when no value returned
- Context managers use `None` from `__enter__` or return self
## Module Design
- All public classes and functions are importable from module
- Private implementation details use `_` prefix (e.g., `_serialize_data`)
- Import and re-export public API: `from .camera import Camera`
- Keep minimum content, delegate to submodules
- Document what's exported from the module
- Use `abc.ABC` and `@abc.abstractmethod` decorator
- Define protocol-level interfaces
- Example: `MotorsBusBase` defines interface all motor bus implementations must follow
## Code Organization Patterns
- Class docstring immediately after class declaration
- Instance attributes initialized in `__init__`
- Properties use `@property` decorator with docstrings
- Abstract methods clearly marked
- Context manager support via `__enter__`/`__exit__`
- Python 3.10+ style: `dict[str, int]` not `Dict[str, int]`
- Union types: `str | int` not `Union[str, int]`
- Optional: `str | None` not `Optional[str]`
- Forward references use `from __future__ import annotations`
## Development Configuration
- Tool: mypy (configured in `pyproject.toml`)
- Enabled selectively: `lerobot.envs`, `lerobot.configs`, `lerobot.optim`, `lerobot.model`, `lerobot.cameras`, `lerobot.motors`, `lerobot.transport`
- Other modules: `ignore_errors = true` (gradual typing)
- Config module has strictest settings: `disallow_untyped_defs`, `disallow_incomplete_defs`, `check_untyped_defs`
- Bandit (PyCQA/bandit v1.8.6) checks in pre-commit
- Gitleaks detection for secrets
- Skips: B101 (assert), B311 (pickle), B404 (subprocess), B603/B615 (shell injection) - these are expected in robotics context
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Pattern Overview
- Plugin-based policy architecture (factory pattern for dynamic policy instantiation)
- Data processing pipeline with composable processor steps
- Separation of concerns: data collection, processing, training, inference
- Multi-robot support through standardized Robot and Teleoperator interfaces
- Offline RL loop: value training → advantage inference (ACP) → policy training with conditioned prompts
## Layers
- Purpose: Standardize interaction with physical robots and teleoperation devices
- Location: `src/lerobot/robots/`, `src/lerobot/teleoperators/`, `src/lerobot/motors/`
- Contains: Robot base class, motor drivers (Dynamixel, Feetech, Damiao/CAN), camera interfaces
- Depends on: Hardware SDKs (piper_sdk, feetech-servo-sdk, dynamixel-sdk, pyserial)
- Used by: Data collection scripts, hardware setup utilities
- Purpose: Transform raw robot observations/actions through composable processor steps
- Location: `src/lerobot/processor/`
- Contains: Base pipeline classes, specialized processor steps (normalization, device placement, batch conversion, image preprocessing, ACP hooks)
- Depends on: Core transition types (RobotObservation, RobotAction, PolicyAction)
- Used by: Data collection loop, inference, training
- Purpose: Load, store, and manage datasets with version control and metadata
- Location: `src/lerobot/datasets/`
- Contains: LeRobotDataset (Hugging Face datasets integration), stats computation, video encoding/decoding
- Depends on: Hugging Face datasets library, PyArrow, OpenCV
- Used by: Training scripts, evaluation, offline RL workflows
- Purpose: Pluggable policy models with configurable preprocessing/postprocessing
- Location: `src/lerobot/policies/` (act/, diffusion/, pi0/, pi05/, sac/, smolvla/, tdmpc/, vqbet/, etc.)
- Contains: Policy classes, configuration objects, model architectures, processor definitions
- Depends on: PyTorch, transformers, diffusers, policy-specific dependencies
- Used by: Training, inference, policy selection via factory
- Purpose: Train and infer value functions to guide policy learning via advantage conditioning
- Location: `src/lerobot/values/pistar06/`
- Contains: Pi*0.6 value model (SigLIP vision encoder + Gemma LM + MLP value head)
- Depends on: Transformers (SigLIP, Gemma), PyTorch
- Used by: RL training pipeline (value-train → value-infer → policy-train with ACP)
- Purpose: Coordinate value training, advantage inference (ACP), and policy training
- Location: `src/lerobot/scripts/lerobot_value_train.py`, `lerobot_value_infer.py`, `lerobot_train.py`, `src/lerobot/rl/`
- Contains: Training entry points, ACP hooks, wandb integration, distributed training utilities
- Depends on: All lower layers
- Used by: End users, experiment orchestration
- Utilities: `src/lerobot/utils/` (constants, logging, device detection, random seeds, training utilities)
- Async Inference: `src/lerobot/async_inference/` (gRPC policy server, robot client for distributed deployment)
- Transports: `src/lerobot/transport/` (gRPC protobuf services)
- Configs: `src/lerobot/configs/` (training config, policy configs, environment configs)
## Data Flow
- **Training State:**
- **Model Checkpoints:**
- **Environment State:**
## Key Abstractions
- Purpose: Abstracts different robotic platforms (SO101, PiPER, Reachy2, etc.)
- Examples: `src/lerobot/robots/bi_so_follower/`, `src/lerobot/robots/bi_piper_follower/`
- Pattern: Subclass `Robot` base class, implement `get_observation()`, `send_action()`, connect/disconnect lifecycle
- Provides: `observation_features`, `action_space` definitions; calibration management
- Purpose: Abstracts input devices (leader arms, keyboards, gamepads, phones)
- Examples: `src/lerobot/teleoperators/bi_so_leader/`, `src/lerobot/teleoperators/keyboard/`, `src/lerobot/teleoperators/gamepad/`
- Pattern: Subclass `Teleoperator`, implement `get_action()`, context manager protocol
- Provides: Action space mapping, event handling
- Purpose: Composable transformation of observations/actions through serializable steps
- Examples: `src/lerobot/processor/normalize_processor.py`, `src/lerobot/processor/device_processor.py`, `src/lerobot/processor/tokenizer_processor.py`
- Pattern: Each step implements `__call__(transition_dict) → transition_dict`, steps chain via composition
- Provides: Serialization to JSON config, loading from pretrained checkpoint
- Purpose: Dynamically instantiate policy models without hard-coding dependencies
- Location: `src/lerobot/policies/factory.py`
- Pattern: `get_policy_class(name: str)` → dynamic import + class retrieval; `make_policy()` constructs full pipeline
- Provides: Extensibility: add new policy type → register in factory, no core code changes
- Purpose: Centralized, type-safe config for training/inference
- Examples: `src/lerobot/configs/train.py`, `src/lerobot/configs/value_train.py`
- Pattern: Dataclass-based (draccus), CLI argument mapping, config merging
- Provides: Full experiment reproducibility, checkpoint resume capability
## Entry Points
- Location: `src/lerobot/scripts/lerobot_record.py`
- Triggers: CLI: `lerobot-record --config_path=configs/record_fold_cloth.yaml`
- Responsibilities: Spawn robot + teleop, run 30 Hz recording loop, save episodes to dataset
- Location: `src/lerobot/scripts/lerobot_human_inloop_record.py`
- Triggers: CLI with optional `--policy.path=<checkpoint>`, `--resume=true`
- Responsibilities: Deploy policy, detect interventions, merge policy + human actions
- Location: `src/lerobot/scripts/lerobot_value_train.py`
- Triggers: CLI: `lerobot-value-train --dataset_repo_id=<path> --value.type=pistar06 --value.model_name_or_path=...`
- Responsibilities: Load dataset, create value model, train, save checkpoint to wandb/local
- Location: `src/lerobot/scripts/lerobot_value_infer.py`
- Triggers: CLI: `lerobot-value-infer --dataset_repo_id=<path> --value.path=<checkpoint> --acp.enable=true`
- Responsibilities: Compute value per frame, binarize advantage, inject labels into dataset, save augmented dataset
- Location: `src/lerobot/scripts/lerobot_train.py`
- Triggers: CLI: `lerobot-train --dataset_repo_id=<path> --policy.type=pi05 --policy.path=<pretrained> --acp.enable=true`
- Responsibilities: Load dataset with ACP indicators, train policy model, log to wandb, save checkpoint
- Location: `src/lerobot/scripts/lerobot_eval.py`
- Triggers: CLI: `lerobot-eval --policy.path=<checkpoint> --dataset_repo_id=<path> --eval.num_episodes=10`
- Responsibilities: Roll out policy on real robot or sim env, compute success rate
- Location: `src/lerobot/scripts/lerobot_teleoperate.py`
- Triggers: CLI: `lerobot-teleoperate --robot.type=bi_piper_follower --teleop.type=bi_piper_leader`
- Responsibilities: Connect robot + teleop, run live control loop (no recording)
## Error Handling
- Hardware disconnection → context manager `__exit__` ensures cleanup; retry logic in recording loop
- Missing calibration → load from fallback or skip (feetech motors); PiPER uses absolute encoders (no calibration needed)
- Device placement errors → auto-detect CUDA/MPS/CPU via `get_safe_torch_device()`, notify user
- Config validation → draccus dataclass validation catches missing required fields early
- Dataset loading → Hugging Face snapshot_download with retry; falls back to local cache
- Model loading → transformers `from_pretrained` with timeout; graceful skip if vision encoder unavailable
## Cross-Cutting Concerns
- Approach: Python `logging` module with `src/lerobot/utils/logging_utils.py` helpers
- Per-module loggers initialized at module level
- Wandb integration in training scripts via `src/lerobot/rl/wandb_utils.py` (optional, respects `--wandb.enable` flag)
- Observation/action schema: Checked against `observation_features` / `action_space` at runtime
- Feature name consistency: `_validate_feature_names()` in dataset loading
- Configuration: Draccus dataclass validation on instantiation
- Hugging Face token: Read from `~/.huggingface/token` or `HF_TOKEN` env var
- Robot hardware credentials: None required (serial ports direct, CAN bus native)
- Dataset access: Repo visibility (public/private) enforced by Hugging Face Hub
- Approach: Centralized `set_seed()` in `src/lerobot/utils/random_utils.py`
- Sets: `random.seed()`, `np.random.seed()`, `torch.manual_seed()`, torch CUDA seed, cuDNN settings
- Called early in training/eval scripts to ensure reproducibility
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
