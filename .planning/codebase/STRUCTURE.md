# Codebase Structure

**Analysis Date:** 2026-03-24

## Directory Layout

```
Evo-RL/
├── src/lerobot/              # Main library (installable via setup.py / pyproject.toml)
│   ├── __init__.py           # Available policies, robots, datasets registry
│   ├── __version__.py        # Version string
│   │
│   ├── robots/               # Robot implementations (hardware abstraction layer)
│   │   ├── robot.py          # Base Robot class with abstract methods
│   │   ├── config.py         # RobotConfig dataclass
│   │   ├── utils.py          # Robot factory & registry
│   │   ├── bi_so_follower/   # SO101 dual-arm (Feetech serial)
│   │   ├── bi_piper_follower/ # AgileX PiPER dual-arm (CAN bus, MIT mode)
│   │   ├── bi_openarm_follower/ # BiOpenArm (Damiao motors)
│   │   ├── so_follower/      # Single SO arm
│   │   ├── piper_follower/   # Single PiPER arm
│   │   └── [...other robots]
│   │
│   ├── teleoperators/        # Teleoperation input devices
│   │   ├── teleoperator.py   # Base Teleoperator class
│   │   ├── utils.py          # Teleop factory
│   │   ├── bi_so_leader/     # SO101 dual-arm leader
│   │   ├── bi_piper_leader/  # PiPER dual-arm leader (gravity comp)
│   │   ├── keyboard/         # Keyboard control
│   │   ├── gamepad/          # Gamepad input
│   │   ├── phone/            # Phone-based teleoperation
│   │   └── [...other teleops]
│   │
│   ├── motors/               # Motor drivers (Dynamixel, Feetech, Damiao/CAN)
│   │   ├── dynamixel/        # Dynamixel SDK wrapper
│   │   ├── feetech/          # Feetech serial servo control
│   │   ├── damiao/           # Damiao CAN motor control
│   │   └── motors_bus.py     # Motor bus abstraction
│   │
│   ├── cameras/              # Camera implementations
│   │   ├── opencv/           # OpenCV (USB cameras)
│   │   ├── realsense/        # Intel RealSense depth cameras
│   │   ├── reachy2_camera/   # Reachy2 arm cameras
│   │   └── zmq/              # ZMQ network camera
│   │
│   ├── processor/            # Data processing pipeline
│   │   ├── core.py           # RobotObservation, RobotAction, PolicyAction types
│   │   ├── pipeline.py       # RobotProcessorPipeline, PolicyProcessorPipeline classes
│   │   ├── base.py           # ProcessorStep base class
│   │   ├── converters.py     # Conversion functions between types
│   │   ├── normalize_processor.py # State/action normalization (QUANTILES/STANDARD)
│   │   ├── device_processor.py # GPU/CPU device placement
│   │   ├── batch_processor.py # Batch dimension addition
│   │   ├── tokenizer_processor.py # Text tokenization for vision-language models
│   │   ├── rename_processor.py # Feature name remapping
│   │   ├── delta_action_processor.py # Delta vs. absolute action conversion
│   │   ├── hil_processor.py  # Human-in-loop specific processors
│   │   ├── env_processor.py  # Environment-specific (Libero, IsaacLab)
│   │   ├── gym_action_processor.py # Gym environment conversion
│   │   └── factory.py        # Processor pipeline factory from config
│   │
│   ├── datasets/             # Dataset management (Hugging Face integration)
│   │   ├── lerobot_dataset.py # LeRobotDataset class (main dataset interface)
│   │   ├── utils.py          # Dataset utilities (loading, validation, stats)
│   │   ├── compute_stats.py  # Episode/frame statistics
│   │   ├── image_writer.py   # Async image encoding/writing
│   │   ├── video_utils.py    # Video codec handling
│   │   ├── factory.py        # Dataset factory
│   │   ├── v30/              # Legacy dataset version 3.0
│   │   └── push_dataset_to_hub/ # Upload utility for Hugging Face
│   │
│   ├── policies/             # Policy implementations (pluggable)
│   │   ├── factory.py        # Policy class factory (dynamic imports)
│   │   ├── pretrained.py     # PreTrainedPolicy base class
│   │   ├── base.py           # Policy base class with training methods
│   │   ├── utils.py          # Shared policy utilities
│   │   ├── act/              # ACT (Action Chunking with Transformers)
│   │   ├── diffusion/        # Diffusion Policy
│   │   ├── pi0/              # PI0 (vision-language policy)
│   │   ├── pi05/             # PI0.5 (improved, text-conditioned)
│   │   │   ├── configuration_pi05.py # Config dataclass
│   │   │   ├── modeling_pi05.py # Model class (PaliGemma + Gemma Expert)
│   │   │   └── processor_pi05.py # Preprocessing pipeline
│   │   ├── pi0_fast/         # PI0 Fast variant
│   │   ├── sac/              # SAC (Soft Actor-Critic, RL-based)
│   │   │   └── reward_model/ # Reward classifier
│   │   ├── smolvla/          # SmolVLA (small vision-language)
│   │   ├── tdmpc/            # TDMPC (Temporal Difference MPC)
│   │   ├── vqbet/            # VQBet (Vector Quantized Behavior)
│   │   ├── groot/            # Gr00t (multimodal token-based)
│   │   ├── sarm/             # SARM (structured reward modeling)
│   │   ├── xvla/             # XVLA (extended VLA)
│   │   ├── wall_x/           # WallX (Qwen2.5-VL based)
│   │   └── rtc/              # RTC (Realtime Control)
│   │
│   ├── values/               # Value function models
│   │   ├── pistar06/         # Pi*0.6 (return-to-go value model)
│   │   │   ├── configuration_pistar06.py # Config: ~670M params
│   │   │   ├── modeling_pistar06.py # SigLIP + Gemma + MLP value head
│   │   │   └── processor_pistar06.py # Preprocessing
│   │   └── __init__.py
│   │
│   ├── scripts/              # CLI entry points
│   │   ├── lerobot_record.py # Data collection script
│   │   ├── lerobot_human_inloop_record.py # HIL recording with policy
│   │   ├── lerobot_teleoperate.py # Live teleoperation (test hardware)
│   │   ├── lerobot_train.py  # Policy training (main training entry)
│   │   ├── lerobot_value_train.py # Value function training
│   │   ├── lerobot_value_infer.py # ACP advantage inference
│   │   ├── lerobot_eval.py   # Policy evaluation
│   │   ├── lerobot_replay.py # Dataset replay
│   │   ├── lerobot_calibrate.py # Motor calibration
│   │   ├── lerobot_dataset_viz.py # Dataset visualization
│   │   ├── lerobot_dataset_report.py # Dataset statistics
│   │   ├── lerobot_edit_dataset.py # Dataset modification
│   │   ├── recording_loop.py # Core 30 Hz recording loop (imported by lerobot_record.py)
│   │   ├── recording_hil.py  # HIL utilities (policy sync, intervention detection)
│   │   ├── value_infer_viz.py # Value inference visualization
│   │   └── [...other utility scripts]
│   │
│   ├── configs/              # Configuration definitions (dataclass-based)
│   │   ├── train.py          # TrainConfig, TrainRLConfig (policy training)
│   │   ├── value_train.py    # ValueTrainConfig (value function training)
│   │   ├── parser.py         # Config CLI argument parsing (draccus)
│   │   ├── policies.py       # Base PreTrainedConfig class
│   │   ├── types.py          # FeatureType enum (VISUAL, STATE, ACTION, etc.)
│   │   └── environment.py    # Environment configs
│   │
│   ├── rl/                   # RL-specific utilities
│   │   ├── learner.py        # Learner server (distributed training coordinator)
│   │   ├── actor.py          # Actor (data collector in distributed setup)
│   │   ├── learner_service.py # Service implementation for gRPC
│   │   ├── buffer.py         # Replay buffer utilities
│   │   ├── queue.py          # IPC queue for inter-process communication
│   │   ├── acp_hook.py       # ACP prompt injection callback
│   │   ├── acp_tags.py       # ACP dataset field names
│   │   ├── acp_dataset_stats.py # ACP-specific statistics
│   │   ├── eval_policy.py    # Policy evaluation utilities
│   │   ├── gym_manipulator.py # Gym environment wrapper
│   │   ├── wandb_utils.py    # Weights & Biases logging
│   │   ├── process.py        # Signal handling, process utilities
│   │   └── joint_observations_processor.py # Joint state assembly
│   │
│   ├── async_inference/      # Distributed policy inference
│   │   ├── policy_server.py  # gRPC policy server (inference endpoint)
│   │   ├── robot_client.py   # gRPC client on robot (action request)
│   │   └── [...test files]
│   │
│   ├── envs/                 # Simulation environments
│   │   ├── factory.py        # Environment factory
│   │   ├── libero.py         # LIBERO task suite
│   │   ├── metaworld.py      # MetaWorld tasks
│   │   └── utils.py
│   │
│   ├── utils/                # Shared utilities
│   │   ├── constants.py      # Global constants (paths, dims, strings)
│   │   ├── utils.py          # Device detection, model loading
│   │   ├── logging_utils.py  # Logging configuration
│   │   ├── train_utils.py    # Checkpoint save/load, step tracking
│   │   ├── random_utils.py   # Seed setting (torch, numpy, random)
│   │   ├── control_utils.py  # Robot control math utilities
│   │   ├── rotation.py       # Rotation representations
│   │   ├── transition.py     # Transition dict operations
│   │   ├── io_utils.py       # File I/O helpers
│   │   ├── hub.py            # Hugging Face Hub integration
│   │   ├── import_utils.py   # Dynamic imports with fallbacks
│   │   ├── decorators.py     # Function decorators
│   │   ├── visualization_utils.py # Plotting/rendering
│   │   ├── piper_sdk.py      # PiPER-specific utilities
│   │   └── rabc.py           # Rate-adaptive buffer controller
│   │
│   ├── transport/            # gRPC communication
│   │   ├── services.proto    # gRPC service definition
│   │   ├── services_pb2.py   # Protobuf generated code
│   │   ├── services_pb2_grpc.py # gRPC generated code
│   │   └── utils.py          # Serialization/deserialization
│   │
│   ├── data_processing/      # Data annotation utilities
│   │   └── sarm_annotations/ # SARM task annotation tool
│   │
│   ├── model/                # Model utilities (not policies)
│   │   └── kinematics.py     # Robot kinematics helpers
│   │
│   ├── optim/                # Optimization utilities
│   │   └── [...optimizer configs and schedulers]
│   │
│   ├── templates/            # Config templates
│   │   └── [...template files]
│   │
│   ├── assets/               # Robot description files
│   │   └── piper_description/ # PiPER URDF and meshes
│   │
│   └── values/
│       └── __init__.py
│
├── tests/                    # Test suite (pytest-based)
│   ├── conftest.py           # Pytest fixtures
│   ├── fixtures/             # Shared test fixtures
│   ├── mocks/                # Mock hardware objects
│   ├── datasets/             # Dataset tests
│   ├── policies/             # Policy tests
│   ├── processor/            # Processor tests
│   ├── rl/                   # RL tests
│   ├── robots/               # Robot tests
│   ├── motors/               # Motor tests
│   ├── cameras/              # Camera tests
│   ├── training/             # Training pipeline tests
│   ├── test_available.py     # Catalog test (available policies/robots)
│   └── [...more tests]
│
├── examples/                 # Example scripts & notebooks
│   ├── training/             # Training examples
│   ├── tutorial/             # Tutorials (act/, async-inf/, diffusion/, pi0/, rl/, smolvla/)
│   ├── dataset/              # Dataset manipulation examples
│   ├── lekiwi/               # Robot-specific examples
│   ├── phone_to_so100/
│   ├── so100_to_so100_EE/
│   ├── rtc/
│   └── [...more examples]
│
├── scripts/                  # Utility scripts (not entry points)
│   ├── train_pen_*.sh        # Training shell scripts
│   ├── eval_bipiper.py       # BiPiper evaluation
│   └── [...more scripts]
│
├── configs/                  # Data collection configs
│   ├── record_fold_cloth.yaml # PiPER fold_cloth recording config
│   ├── record_pen.yaml       # SO101 pen config
│   └── 99-piper-can.rules    # Udev rules for PiPER CAN
│
├── docs/                     # Documentation (markdown + source files)
│   ├── README.md             # Docs index
│   ├── source/               # MDX documentation files
│   │   ├── installation.mdx
│   │   ├── hardware setup guides (damiao.mdx, feetech.mdx, etc.)
│   │   ├── policy guides (act.mdx, diffusion.mdx, etc.)
│   │   ├── processor.mdx
│   │   ├── bring_your_own_policies.mdx
│   │   └── [...more docs]
│   ├── huawei_npu_training_plan.md
│   └── reproduction_guide.md
│
├── benchmarks/               # Performance benchmarks
│   └── video/                # Video codec benchmark
│
├── website/                  # Static website
│   ├── index.html
│   ├── app.js
│   └── assets/
│
├── pyproject.toml            # Project metadata, dependencies, tool configs
├── setup.py                  # Package installation
├── MANIFEST.in               # Package manifest
├── README.md                 # Main README
├── memorandum.md             # Project documentation (Chinese)
├── LICENSE                   # Apache 2.0
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
└── .pre-commit-config.yaml   # Pre-commit hooks (ruff, typos)
```

## Directory Purposes

**src/lerobot:**
- Purpose: Main library code (installable)
- Contains: All production code organized by abstraction layer
- Key files: `__init__.py` (registry), `__version__.py`

**src/lerobot/robots/:**
- Purpose: Robot hardware implementations
- Contains: Robot base class (`robot.py`), concrete robots (bi_so_follower, bi_piper_follower, etc.), config classes
- Key files: `robot.py` (abstract), `utils.py` (factory), subdirs with robot-specific code

**src/lerobot/teleoperators/:**
- Purpose: Teleoperation input device implementations
- Contains: Teleoperator base class, concrete devices (keyboard, gamepad, phone, leader arms)
- Key files: `teleoperator.py`, `utils.py` (factory)

**src/lerobot/processor/:**
- Purpose: Data transformation pipeline (observation/action preprocessing)
- Contains: Pipeline classes, processor steps, converters
- Key files: `core.py` (types), `pipeline.py` (composition), base step classes, factory

**src/lerobot/datasets/:**
- Purpose: Dataset management and I/O
- Contains: LeRobotDataset class, stats computation, video encoding, Hugging Face integration
- Key files: `lerobot_dataset.py`, `utils.py`, `compute_stats.py`

**src/lerobot/policies/:**
- Purpose: Policy model implementations
- Contains: Factory, base classes, 15+ policy architectures (act, diffusion, pi0, pi05, sac, etc.)
- Key files: `factory.py`, policy subdirs each with (configuration, modeling, processor)

**src/lerobot/values/pistar06/:**
- Purpose: Value function training and inference
- Contains: Pi*0.6 model (SigLIP + Gemma + MLP), configuration, preprocessing
- Key files: `modeling_pistar06.py`, `configuration_pistar06.py`, `processor_pistar06.py`

**src/lerobot/scripts/:**
- Purpose: CLI entry points (installed as lerobot-* commands)
- Contains: Data collection, training, evaluation, hardware utilities
- Key files: `lerobot_record.py`, `lerobot_train.py`, `lerobot_value_train.py`, `lerobot_value_infer.py`, `lerobot_eval.py`, `recording_loop.py` (core loop)

**src/lerobot/configs/:**
- Purpose: Configuration definitions (dataclass-based, CLI-parsed)
- Contains: Training configs, policy configs, environment configs, parser
- Key files: `train.py`, `value_train.py`, `parser.py` (draccus integration)

**src/lerobot/rl/:**
- Purpose: RL-specific utilities (value training, ACP hooks, distributed training)
- Contains: Learner/actor for distributed setup, replay buffer, ACP hooks, wandb logging
- Key files: `learner.py`, `acp_hook.py`, `acp_tags.py`, `wandb_utils.py`

**src/lerobot/async_inference/:**
- Purpose: Distributed inference (policy server + robot client via gRPC)
- Contains: Server/client for remote policy execution
- Key files: `policy_server.py`, `robot_client.py`

**src/lerobot/utils/:**
- Purpose: Shared utilities across modules
- Contains: Constants, device detection, seeding, logging, checkpoint management
- Key files: `constants.py`, `utils.py`, `random_utils.py`, `train_utils.py`

**tests/:**
- Purpose: Test suite (pytest)
- Contains: Unit tests, integration tests, mocks, fixtures
- Key files: `conftest.py`, per-module test files (test_policies.py, test_datasets.py, etc.)

**examples/:**
- Purpose: Example scripts and tutorials
- Contains: Training examples, dataset tools, robot-specific examples
- Key files: Tutorial notebooks and Python scripts

**scripts/:**
- Purpose: Utility scripts (not CLI entry points)
- Contains: Training shell scripts, evaluation scripts
- Key files: train_pen_*.sh, eval_bipiper.py

**configs/:**
- Purpose: Data collection configuration files
- Contains: YAML configs for recording different tasks/robots
- Key files: record_fold_cloth.yaml, record_pen.yaml

**docs/:**
- Purpose: User documentation
- Contains: Installation guide, hardware setup, policy guides, reproduction guide
- Key files: source/*.mdx (MDX format), README.md

## Key File Locations

**Entry Points:**
- `src/lerobot/scripts/lerobot_record.py`: Main data collection CLI
- `src/lerobot/scripts/lerobot_human_inloop_record.py`: HIL-enabled recording with policy
- `src/lerobot/scripts/lerobot_train.py`: Policy training CLI
- `src/lerobot/scripts/lerobot_value_train.py`: Value function training
- `src/lerobot/scripts/lerobot_value_infer.py`: ACP advantage labeling
- `src/lerobot/scripts/lerobot_eval.py`: Policy evaluation

**Configuration:**
- `pyproject.toml`: Package metadata, dependencies (torch, transformers, datasets, etc.), tool configs (ruff, mypy)
- `setup.py`: Installation script
- `src/lerobot/configs/train.py`: TrainConfig (policy training hyperparams)
- `src/lerobot/configs/value_train.py`: ValueTrainConfig
- `configs/record_fold_cloth.yaml`: Example data collection config (PiPER)

**Core Logic:**
- `src/lerobot/datasets/lerobot_dataset.py`: LeRobotDataset (main dataset interface)
- `src/lerobot/robots/robot.py`: Robot base class (abstract methods)
- `src/lerobot/teleoperators/teleoperator.py`: Teleoperator base class
- `src/lerobot/policies/factory.py`: Policy instantiation (dynamic imports)
- `src/lerobot/policies/pi05/modeling_pi05.py`: PI0.5 policy (default for ACP)
- `src/lerobot/values/pistar06/modeling_pistar06.py`: Pi*0.6 value function
- `src/lerobot/processor/pipeline.py`: Processor pipeline composition
- `src/lerobot/rl/acp_hook.py`: ACP prompt injection callback
- `src/lerobot/scripts/recording_loop.py`: 30 Hz data collection loop (core)

**Testing:**
- `tests/conftest.py`: Pytest fixtures (datasets, mocks, etc.)
- `tests/test_available.py`: Catalog validation test
- `tests/policies/test_policies.py`: Policy instantiation tests
- `tests/datasets/test_datasets.py`: Dataset loading tests
- `tests/robots/` & `tests/mocks/`: Robot & mock implementations for testing

**Utilities:**
- `src/lerobot/utils/constants.py`: Global constants (paths, action/state keys)
- `src/lerobot/utils/utils.py`: Device detection, model loading helpers
- `src/lerobot/utils/random_utils.py`: Seed setting (torch, numpy, random)
- `src/lerobot/utils/train_utils.py`: Checkpoint save/load, step tracking

## Naming Conventions

**Files:**
- `modeling_<module>.py`: Model class definition
- `configuration_<module>.py`: Config dataclass
- `processor_<module>.py`: Preprocessing pipeline definition
- `test_<module>.py`: Test file for module
- `lerobot_<command>.py`: CLI entry point script

**Directories:**
- `<robot_type>_follower/`: Follower (controlled) robot implementations
- `<robot_type>_leader/`: Leader (input device) implementations
- `<policy_type>/`: Policy subdirectory (act, diffusion, pi0, pi05, etc.)
- `<motor_type>/`: Motor driver subdirectory

**Classes:**
- `<RobotType>Follower`: Concrete robot class (e.g., BiSoFollower, BiPiperFollower)
- `<RobotType>Leader`: Concrete teleop class
- `<MotorType>Motor`: Motor driver class
- `<PolicyName>Policy`: Policy class (e.g., ACTPolicy, DiffusionPolicy, PI05Policy)
- `<FeatureName>ProcessorStep`: Processor step class
- `<ConfigName>Config`: Configuration dataclass

**Functions:**
- `make_<thing>()`: Factory function (e.g., `make_policy()`, `make_dataset()`)
- `get_<thing>()`: Getter/accessor (e.g., `get_policy_class()`)
- `<action>_<resource>()`: Action-resource pairs (e.g., `load_calibration()`, `save_checkpoint()`)

## Where to Add New Code

**New Policy:**
1. Create `src/lerobot/policies/<policy_name>/` directory
2. Add `configuration_<policy_name>.py` (dataclass inheriting PreTrainedConfig)
3. Add `modeling_<policy_name>.py` (class inheriting PreTrainedPolicy)
4. Add `processor_<policy_name>.py` (preprocessor/postprocessor pipelines)
5. Register in `src/lerobot/policies/factory.py` → `get_policy_class()` function
6. Add tests in `tests/policies/test_<policy_name>.py` (or expand `test_policies.py`)
7. Add example in `examples/training/`

**New Robot:**
1. Create `src/lerobot/robots/<robot_name>_follower/` directory
2. Add `config.py` (RobotConfig subclass with hardware params)
3. Add `robot.py` (Robot subclass implementing abstract methods)
4. Register in `src/lerobot/robots/utils.py` → factory
5. Create corresponding `src/lerobot/teleoperators/<robot_name>_leader/` (same structure)
6. Register in `src/lerobot/teleoperators/utils.py` → factory
7. Add tests in `tests/robots/test_<robot_name>.py`
8. Add documentation in `docs/source/<robot_name>.mdx`

**New Processor Step:**
1. Create class inheriting appropriate base (`ProcessorStep`, `ObservationProcessorStep`, etc.) in `src/lerobot/processor/`
2. Implement `__call__()` method (transform transition dict)
3. Implement `to_dict()` for serialization (if needed)
4. Add factory support in `src/lerobot/processor/factory.py` if applicable
5. Add test in `tests/processor/test_<processor_name>.py`

**New Hardware Motor Driver:**
1. Create `src/lerobot/motors/<motor_type>/` directory
2. Add `__init__.py` (exports)
3. Add motor driver class (inheriting from base if exists)
4. Add calibration/parameter handling
5. Add tests in `tests/motors/test_<motor_type>.py`
6. Register in motor factory if applicable

**New Training Script/Utility:**
1. Add as `src/lerobot/scripts/lerobot_<function>.py`
2. Main function should accept draccus config and CLI args
3. Register in `pyproject.toml` under `[project.scripts]`
4. Add to CLI entry points: `lerobot-<function>` command
5. Add documentation in `docs/source/`

**New Test:**
1. Place in `tests/<module>/test_<feature>.py`
2. Use fixtures from `tests/conftest.py` or create in file
3. Use mocks from `tests/mocks/` for hardware
4. Run with `pytest tests/<path>` or `make test`

## Special Directories

**src/lerobot/assets/:**
- Purpose: Static assets (robot description files)
- Generated: No (checked in)
- Committed: Yes
- Contents: URDF, mesh files for robot kinematics

**outputs/:**
- Purpose: Training checkpoints and logs
- Generated: Yes (created by lerobot_train.py)
- Committed: No (in .gitignore)
- Contents: pretrained_model/, training_state/, meta logs

**logs/:**
- Purpose: Runtime logs (policy_server, robot_client)
- Generated: Yes (during execution)
- Committed: No
- Contents: .log files with timestamps

**pretrained/:**
- Purpose: Pre-downloaded model weights (tokenizers, vision encoders)
- Generated: Yes (on first use via huggingface_hub)
- Committed: No (large files)
- Contents: PaliGemma tokenizer, other model artifacts

