# Technology Stack

**Analysis Date:** 2026-03-24

## Languages

**Primary:**
- Python 3.10+ - Core language for all robotic simulation, policy training, and control code

## Runtime

**Environment:**
- Python 3.10 (minimum requirement)

**Package Manager:**
- pip/setuptools - Standard Python package management
- Lockfile: `requirements-ubuntu.txt` and `requirements-macos.txt` (compiled from requirements.in)

## Frameworks & Core Libraries

**Deep Learning & ML:**
- PyTorch 2.7.1 - Neural network training and inference for policies
- TorchVision 0.22.1 - Computer vision utilities for image processing
- Transformers 4.57.1 - Pre-trained language/vision models for policy architectures
- Diffusers 0.35.2 - Diffusion-based policy implementations

**Robotics & Control:**
- Gymnasium 1.2.1 - Environment API for RL training
- gym-aloha 0.1.3 - ALOHA robot simulation environment
- gym-pusht 0.1.6 - PushT task simulation
- gym-hil 0.1.13 - Human-in-the-loop training environment
- Piper SDK 0.6.1+ - Piper robot hardware control
- Reachy2 SDK 1.0.14 - Reachy2 robot hardware interface
- DynamixelSDK 3.8.4 - Dynamixel motor control
- Feetech Servo SDK 1.0.0 - Feetech motor control
- pin 3.4.0 & placo 0.9.14 - Robot kinematics and inverse kinematics (PyPinocchio)

**Dataset & Hub Integration:**
- HuggingFace Hub 0.35.3 - Model and dataset downloading/uploading
- Datasets 4.1.1 - HF dataset loading and processing
- Accelerate 1.11.0 - Multi-GPU/TPU training utilities

**Experiment Tracking & Monitoring:**
- Weights & Biases (wandb) 0.21.4 - Experiment logging and tracking
- Rerun SDK 0.26.1 - Real-time 3D visualization for robotics debugging
- Tensorboard 2.20.0 - Training metrics visualization

**Configuration Management:**
- Draccus 0.10.0 - Dataclass-based configuration management
- Hydra Core 1.3.2 - Configuration composition framework
- OmegaConf 2.3.0 - Configuration object library
- PyYAML 6.0.3 - YAML configuration parsing

**Computer Vision:**
- OpenCV Python Headless 4.12.0.88 - Image processing without GUI
- Pillow 12.0.0 - Image manipulation
- av 15.1.0 - Audio/video codec handling
- TorchCodec 0.5 - Video frame decoding
- ImageIO + ffmpeg 2.37.0 - Media file I/O

**Data Processing:**
- NumPy 2.2.6 - Numerical computing
- Pandas 2.3.3 - Data manipulation and analysis
- einops 0.8.1 - Tensor operation abstractions
- Scikit-image 0.25.2 - Image processing algorithms
- Decord 0.6.0 - Video decoding for training data

**Math & Scientific Computing:**
- SciPy 1.15.3 - Scientific computing routines
- Matplotlib 3.10.7 - Plotting and visualization
- dm-control 1.0.34 - DeepMind Control Suite environments
- MuJoCo 3.3.7 - Physics simulation engine
- CasADi 3.6.0 - Symbolic math and optimization

**Testing:**
- pytest 8.4.2 - Test framework
- pytest-cov 7.0.0 - Coverage reporting
- pytest-timeout 2.4.0 - Test timeout management

**Development & Code Quality:**
- Ruff 0.14.1 - Fast Python linter and formatter
- Pre-commit 4.3.0 - Git hooks framework
- MyPy 1.19.1 - Static type checking
- Bandit 1.8.6 - Security linting
- Typos 1.38.1 - Spell checking

**Hardware Communication:**
- pySerial 3.5 - Serial port communication
- PyInput 1.8.1 - Keyboard/mouse input
- PyZMQ 27.1.0 - Zero Message Queue for distributed control
- python-can 4.2.0 - CAN bus communication
- gRPC 1.73.1 - RPC framework for async operations

**Utilities:**
- termcolor 3.1.0 - Colored terminal output
- tqdm 4.67.1 - Progress bars
- jsonlines 4.0.0 - JSONL file handling
- deepdiff 8.6.1 - Deep comparison utilities
- packaging 25.0 - Version parsing
- peft 0.17.1 - Parameter-efficient fine-tuning

## Configuration Files

**Package Configuration:**
- `pyproject.toml` - Project metadata and dependencies
- `setup.py` - Setup script for editable installation

**Development:**
- `.pre-commit-config.yaml` - Git hooks for code quality
- `pyproject.toml` [tool.ruff] - Linting and formatting rules
- `pyproject.toml` [tool.mypy] - Type checking configuration

**Dependencies:**
- `requirements-ubuntu.txt` - Complete Ubuntu dependency lock file
- `requirements-macos.txt` - Complete macOS dependency lock file
- `requirements.in` - Base requirements for compilation

## Platform Requirements

**Development:**
- Python 3.10+
- pip + setuptools
- Git
- Pre-commit hooks (optional but recommended)

**Production/Deployment:**
- GPU support: CUDA 12 (nvidia packages included)
- macOS: Native PyObjC support for system integration
- Linux: Standard x86_64 or ARM64 support

**Optional Hardware Support:**
- Piper robots (via piper_sdk)
- Reachy2 robots (via reachy2_sdk)
- Dynamixel motors (via dynamixel-sdk)
- Feetech motors (via feetech-servo-sdk)
- Intel RealSense cameras (via pyrealsense2)
- HEBI robotics (via hebi-py)

## Key Dependencies by Function

**Policy Training:**
- torch, torchvision, transformers, accelerate, wandb, rerun-sdk

**Data Loading:**
- datasets, huggingface-hub, imageio, av, torchcodec, decord

**Environment Simulation:**
- gymnasium, gym-aloha, gym-pusht, gym-hil, mujoco, dm-control

**Robot Hardware Control:**
- piper_sdk, reachy2_sdk, dynamixel-sdk, feetech-servo-sdk, pyserial, pyzmq

**Visualization:**
- matplotlib, rerun-sdk, meshcat

---

*Stack analysis: 2026-03-24*
