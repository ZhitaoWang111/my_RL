# External Integrations

**Analysis Date:** 2026-03-24

## APIs & External Services

**Model & Dataset Hub:**
- Hugging Face Hub - Dataset and model downloading/uploading
  - SDK/Client: `huggingface-hub==0.35.3`
  - Auth: HF_TOKEN environment variable (implicit via huggingface-hub CLI)
  - Usage: Model loading, pretrained weights, dataset distribution
  - Files: `src/lerobot/utils/hub.py`, `src/lerobot/configs/policies.py`, `src/lerobot/configs/train.py`

**Experiment Tracking:**
- Weights & Biases (wandb) - Training run logging and monitoring
  - SDK/Client: `wandb==0.21.4`
  - Auth: WANDB_API_KEY environment variable
  - Usage: Log metrics, videos, hyperparameters during training
  - Files: `src/lerobot/rl/wandb_utils.py`
  - Config: `os.environ["WANDB_SILENT"]` toggle available

**3D Visualization & Debugging:**
- Rerun - Real-time visualization of robot states and trajectories
  - SDK/Client: `rerun-sdk==0.26.1`
  - Usage: Debug policy behavior, visualize observations
  - Optional for most workflows

**Robotics Simulation:**
- Google DeepMind Control Suite - Environment simulation
  - SDK/Client: `dm-control==1.0.34`
  - Usage: Simulated environments for policy training

- MuJoCo - Physics engine for simulation
  - SDK/Client: `mujoco==3.3.7`
  - Usage: Underlying physics for simulation environments

## Data Storage & Datasets

**Datasets:**
- HuggingFace Datasets - Cloud dataset management
  - Client: `datasets==4.1.1`
  - Caching: `.cache/huggingface/datasets` (configurable)
  - Usage: Load training datasets, splits management
  - Files: `src/lerobot/datasets/`

**File Storage:**
- Local filesystem only for model checkpoints
  - Default location: `./outputs/` for training runs
  - Pretrained models: `.planning/codebase/../pretrained/` directory
  - Checkpoint path: `outputs/{env}/{policy}_train/checkpoints/{step}/`

**Video/Media Storage:**
- Local media files via imageio, av, torchcodec
  - Supported formats: MP4, MKV (via ffmpeg)

## Authentication & Identity

**Auth Provider:**
- HuggingFace OAuth (implicit)
  - Implementation: huggingface-cli login or HF_TOKEN env var
  - Scope: Model hub access, dataset access, organization access

- Weights & Biases OAuth (implicit)
  - Implementation: wandb login or WANDB_API_KEY env var
  - Scope: Experiment tracking, project access

## Robot Hardware Integrations

**Robot Platforms:**

**Piper (Humanoid):**
- SDK: `piper_sdk>=0.6.1,<0.7.0`
- Files: `src/lerobot/teleoperators/piper_leader/piper_leader.py`, `src/lerobot/robots/piper/`
- Communication: Serial/network via Piper SDK

**Reachy2:**
- SDK: `reachy2_sdk==1.0.14`, `reachy2_sdk_api==1.0.21`
- gRPC: `grpcio==1.73.1`
- Files: `src/lerobot/teleoperators/reachy2_teleoperator/`, `src/lerobot/robots/reachy2/`
- Communication: gRPC over network

**Dynamixel Motors:**
- SDK: `dynamixel-sdk==3.8.4`
- Serial: `pyserial>=3.5`
- Files: `src/lerobot/motors/dynamixel/dynamixel.py`
- Communication: Serial port (configurable COM port)

**Feetech Motors:**
- SDK: `feetech-servo-sdk==1.0.0`
- Serial: `pyserial>=3.5`
- Files: `src/lerobot/motors/feetech/feetech.py`
- Communication: Serial port

**Unitree G1 (Humanoid):**
- Additional: `onnxruntime>=1.16.0`, `pin>=3.0.0`, `meshcat>=0.3.0`, `casadi>=3.6.0`
- Kinematics: PyPinocchio integration

**Intel RealSense Cameras:**
- SDK: `pyrealsense2==2.56.5.9235` (Linux), `pyrealsense2-macosx==2.54.2` (macOS)
- Files: `src/lerobot/cameras/intelrealsense/`
- USB: Direct hardware access

**HEBI Robotics:**
- SDK: `hebi-py==2.11.0`
- Files: Robot-specific control

**Phone/Mobile Control:**
- FastAPI: `fastapi<1.0` (for teleop endpoint)
- Teleop: `teleop==0.1.2`
- WebSocket: Direct connection

## Communication Protocols

**Serial Communication:**
- Port: Auto-detected via `lerobot-find-port` script
- Baud rates: Device-specific (handled by respective SDKs)
- Files: Device configuration in `src/lerobot/robots/` and `src/lerobot/motors/`

**Network/RPC:**
- gRPC 1.73.1 for Reachy2 and distributed training
- ZMQ (PyZMQ 27.1.0) for process communication
- HTTP/WebSocket via FastAPI for phone control

**CAN Bus:**
- python-can 4.2.0 for OpenArms robot (damiao motors)
- Configuration: Device-specific in robot configs

## Monitoring & Observability

**Error Tracking:**
- None detected (could use Sentry but not integrated)

**Logs:**
- Built-in Python logging
- W&B integration via `wandb_utils.py`
- Rerun visualization for debugging

**Checkpointing:**
- Local filesystem: PyTorch save/load
- Location: `outputs/{run_name}/checkpoints/`
- Formats: `.safetensors`, `.pt`, `.pth`

## CI/CD & Deployment

**Hosting:**
- None (local development/training)

**CI Pipeline:**
- Pre-commit hooks: Ruff, MyPy, Bandit, Typos
- Testing: pytest framework
- No cloud deployment infrastructure detected

## Environment Configuration

**Required env vars:**
- `HF_TOKEN` (for model/dataset hub access, optional if using public models)
- `WANDB_API_KEY` (for W&B tracking, optional)
- `WANDB_SILENT=True` (auto-set in wandb_utils.py when not logging)

**Optional env vars:**
- `PYGAME_HIDE_SUPPORT_PROMPT=1` (set in calibration GUI)
- `CUDA_*` (automatic via PyTorch)

**Secrets location:**
- Handled via environment variables
- HF: `~/.cache/huggingface/token`
- W&B: `~/.wandb/settings`

## Webhooks & Callbacks

**Incoming:**
- None detected

**Outgoing:**
- W&B run completion hooks (implicit)
- HuggingFace Hub upload on model save

## Model & Dataset Management

**Model Hub Integration:**
- Repository: huggingface.co/lerobot
- Push command: Via `HfApi.upload_folder()` in training scripts
- Pull command: Via `hf_hub_download()` in configs
- Files: `src/lerobot/utils/hub.py`, `src/lerobot/configs/policies.py`

**Dataset Hub Integration:**
- Datasets auto-downloaded from huggingface.co/datasets
- Caching: `~/.cache/huggingface/datasets/`
- Configuration: Dataset repo_id in config files `src/lerobot/configs/`

## Configuration Loading

**From Hub:**
- Model configs downloaded via `hf_hub_download(repo_id, filename="config.json")`
- Policy configs: `src/lerobot/configs/policies.py`
- Train configs: `src/lerobot/configs/train.py`
- Error handling: `HfHubHTTPError` caught for missing configs

---

*Integration audit: 2026-03-24*
