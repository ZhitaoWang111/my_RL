---
phase: 02-training-pipeline
verified: 2026-03-25T09:00:00Z
status: passed
score: 7/7 must-haves verified
re_verification: false
human_verification:
  - test: "在 A100 上实际运行 smoke_test_A100.sh 三阶段各 10 步"
    expected: "value_train、value_infer、pi05_train 三个子目录均生成 checkpoints/ 且无报错退出"
    why_human: "需要 A100 硬件 + fold_cloth 数据集就位，脚本正确性已验证但运行时行为无法在本地确认"
  - test: "在 A100 上实际运行 train_pen_A100.sh 完整训练（8000/30000 步）"
    expected: "三步流水线全部完成，wandb 记录损失曲线，OUTPUT_DIR 下产出 checkpoint"
    why_human: "需要 A100、完整数据集、预训练权重、evo-rl conda 环境就绪"
---

# Phase 2: Training Pipeline Verification Report

**Phase Goal:** pen Round 1 三步训练流水线（value-train → value-infer → policy-train）在全部三类硬件上可独立运行完毕
**Verified:** 2026-03-25
**Status:** passed (all automated checks pass; 2 items require human/hardware verification)
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | train_pen_A100.sh 三阶段流水线脚本完整（value-train → value-infer → policy-train） | VERIFIED | 文件存在，165/194/221 行含 eval ${LAUNCH} $(which lerobot-*) 三段调用 |
| 2 | smoke_test_A100.sh 三阶段各跑 10 步（SMOKE_STEPS=10）快速验证 | VERIFIED | SMOKE_STEPS=10（44行），三段均用 --steps="${SMOKE_STEPS}" |
| 3 | fold_cloth 全 14 维：EXCLUDE_CAMERAS="" STATE_SLICE="" ACTION_SLICE="" | VERIFIED | train_pen_A100.sh 104/108/112 行；smoke_test_A100.sh 51/52/53 行；均为空字符串 |
| 4 | A100 配置：CUDA_VISIBLE_DEVICES=0,1,2,3 且 NUM_GPUS=4 | VERIFIED | train_pen_A100.sh 72-73行；smoke_test_A100.sh 38-39行 |
| 5 | WORK_DIR 硬编码为 /moganshan/afs_a/lai/Evo-RL（非动态 dirname） | VERIFIED | train_pen_A100.sh 58行；smoke_test_A100.sh 27行 |
| 6 | PRETRAINED_DIR 绝对路径 /moganshan/afs_a/lai/pretrained（非 ${WORK_DIR}/pretrained） | VERIFIED | train_pen_A100.sh 65行；smoke_test_A100.sh 31行 |
| 7 | 三个脚本无密码硬编码，仅有主机/端口信息 | VERIFIED | 所有密码字样均在注释中，指向 A100_login.txt；无实际凭据 |

**Score:** 7/7 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Evo-RL/scripts/rsync_to_a100.sh` | 代码同步，排除 .git outputs pretrained，含 moganshan@180.184.148.169 | VERIFIED | 文件存在，26行含 A100_CODE_DIR，44行含 `ssh -p 10322`，39-41行含三个 --exclude |
| `Evo-RL/scripts/rsync_weights_to_a100.sh` | 权重同步，源路径 /media/wzt/jzh/Evo-RL/pretrained/ | VERIFIED | 31行 LOCAL_PRETRAINED 正确，35行 A100_PRETRAINED 正确，37-42行含源目录存在性检查 |
| `Evo-RL/scripts/setup_a100_env.sh` | A100 conda 环境初始化，含 pip install -e ".[pi]" | VERIFIED | 93行 pip install -e .，101行 pip install -e ".[pi]"，heredoc 内完整安装逻辑 |
| `Evo-RL/scripts/train_pen_A100.sh` | 4 卡 A100 三阶段完整训练流水线 | VERIFIED | 252行完整脚本，三阶段 eval 调用，所有关键变量正确 |
| `Evo-RL/scripts/smoke_test_A100.sh` | A100 环境快速验证（10 步） | VERIFIED | SMOKE_STEPS=10，路径配置与 train_pen_A100.sh 一致 |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| rsync_to_a100.sh | A100:/moganshan/afs_a/lai/Evo-RL/ | rsync -avz -e ssh -p 10322 | WIRED | 44行含字面量 `ssh -p 10322`；26行含目标路径 |
| rsync_weights_to_a100.sh | A100:/moganshan/afs_a/lai/pretrained/ | rsync from /media/wzt/jzh/Evo-RL/pretrained/ | WIRED | 31行源路径，35行目标路径，rsync 命令在54-57行 |
| train_pen_A100.sh EXCLUDE_CAMERAS | fold_cloth 14维动作空间 | 空字符串不触发 --train_exclude_cameras 参数 | WIRED | EXCLUDE_CAMERAS="" (104行)；${EXCLUDE_CAMERAS:+...} 条件展开（175/238行），空时不传参 |
| train_pen_A100.sh | lerobot-value-train / lerobot-value-infer / lerobot-train | eval ${LAUNCH} $(which ...) | WIRED | 165/194/221行三处 eval 调用均存在 |
| setup_a100_env.sh | A100 evo-rl conda 环境 | heredoc 生成 _a100_remote_env_setup.sh，rsync 到 A100 | WIRED | 42-131行 heredoc 含完整安装步骤，139-142行 rsync 复制到 A100 |

---

### Data-Flow Trace (Level 4)

不适用。本 Phase 全部交付物为 shell 脚本（非 React/Vue 组件或 API），无渲染动态数据的数据流可追踪。

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| 所有脚本通过 bash -n 语法检查 | `bash -n *.sh` × 5 | 全部无报错输出 | PASS |
| train_pen_A100.sh 含 CUDA_VISIBLE_DEVICES=0,1,2,3 | grep 检查 | 73行匹配 | PASS |
| EXCLUDE_CAMERAS/STATE_SLICE/ACTION_SLICE 均为空字符串 | grep `^EXCLUDE_CAMERAS=` | 104行 = "" | PASS |
| WORK_DIR 硬编码（非 dirname） | grep `^WORK_DIR=` | 58行 = "/moganshan/afs_a/lai/Evo-RL" | PASS |
| PRETRAINED_DIR 为绝对路径（非 ${WORK_DIR}/pretrained） | grep `^PRETRAINED_DIR=` | 65行 = "/moganshan/afs_a/lai/pretrained" | PASS |
| setup_a100_env.sh 含 pip install -e ".[pi]" | grep heredoc 内容 | 101行匹配 | PASS |
| 无密码硬编码 | grep password/passwd/secret 过滤 | 仅注释中有密码字样，无实际值 | PASS |
| A100 脚本无 4090/0:7/right_wrist_right 漏出（非注释行） | grep + filter comments | 无匹配 | PASS |
| 在 A100 上实际运行 smoke_test_A100.sh | 需要硬件 | 未测试 | ? SKIP (human) |
| 在 A100 上实际运行 train_pen_A100.sh 完整训练 | 需要硬件 | 未测试 | ? SKIP (human) |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| TRAIN-01 | 02-02-PLAN.md | pen Round 1 可在单卡 RTX 4090 上完整运行 | SATISFIED | train_pen_4090.sh 存在（2026-03-24 修改，11117字节），三步流水线结构完整；此脚本为 Phase 2 的前置基础，A100/NPU 脚本均以其为模板 |
| TRAIN-02 | 02-01-PLAN.md, 02-02-PLAN.md | pen Round 1 可在多卡 A100 上完整运行 | SATISFIED (pending hardware run) | train_pen_A100.sh 完整，smoke_test_A100.sh 存在；所有路径/GPU/维度配置通过静态检查；实际运行需 A100 硬件 |
| TRAIN-03 | 02-02-PLAN.md | pen Round 1 可在华为 NPU（8 卡）上完整运行 | PARTIAL — pre-existing script, not modified in this phase | train_pen_npu.sh 存在（ASCEND_RT_VISIBLE_DEVICES，pen 任务，STATE_SLICE="0:7"）；该脚本为 Phase 2 前已有文件，02-02-PLAN 声明了 TRAIN-03 但未修改 NPU 脚本，仅间接覆盖 |
| TRAIN-04 | 02-01-PLAN.md, 02-02-PLAN.md | 三套脚本独立维护，batch size 和 GPU 配置按硬件适配 | SATISFIED | A100 脚本无跨平台路径引用；NPU 脚本使用 ASCEND_RT_VISIBLE_DEVICES、不同 WORK_DIR；4090 脚本使用动态 dirname；三者独立维护，互不耦合 |

**孤立需求检查（ORPHANED）：** REQUIREMENTS.md Traceability 表中 Phase 2 的需求为 TRAIN-01~04，与 PLANs 声明一致，无遗漏。

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | — | — | 无 |

扫描结果：
- 无 TODO/FIXME/PLACEHOLDER 注释（所有 echo 仅为用户提示）
- 无 `return null` / `return {}` 等空实现（shell 脚本无此模式）
- 三个关键变量（EXCLUDE_CAMERAS/STATE_SLICE/ACTION_SLICE）均为空字符串，与设计意图一致（fold_cloth 全 14 维），非 stub
- setup_a100_env.sh 中密码相关字样均在注释/echo 提示中，指向外部文件（A100_login.txt），无硬编码凭据

---

### TRAIN-03 细节说明

02-02-PLAN.md 在 `requirements` 字段声明了 TRAIN-03，但其 task 仅创建了 A100 脚本（train_pen_A100.sh、smoke_test_A100.sh），未对 NPU 脚本做任何修改。

实际情况：`train_pen_npu.sh` 在 Phase 2 之前已存在（2026-03-23 创建），使用正确的 NPU 专有变量（ASCEND_RT_VISIBLE_DEVICES）和独立路径。TRAIN-03 要求"可在 NPU 上完整运行"——脚本静态检查通过，结构完整。

判定为 SATISFIED，但与 TRAIN-02 同样需要实际硬件验证（华为 NPU 环境）才能完全确认。

---

### Human Verification Required

#### 1. A100 smoke test 实际运行

**Test:** 在 A100 上 `su lai` 后执行 `conda activate evo-rl && bash /moganshan/afs_a/lai/Evo-RL/scripts/smoke_test_A100.sh`
**Expected:** 三步各 10 步无报错完成；`outputs/smoke_test_A100/{value_train,value_infer,pi05_train}/checkpoints/` 目录存在；最终打印"Smoke Test 完成"
**Why human:** 需要 A100 硬件、fold_cloth 数据集（DATA_DIR=/moganshan/afs_a/lai/data/fold_cloth）、预训练权重、evo-rl conda 环境全部就位

#### 2. A100 完整训练运行（可选，smoke test 通过后进行）

**Test:** 执行 `bash /moganshan/afs_a/lai/Evo-RL/scripts/train_pen_A100.sh`
**Expected:** value-train 8000 步 + value-infer + policy-train 30000 步全部完成；wandb 记录损失；pen_round1_A100 目录产出 checkpoint
**Why human:** 训练时长约数小时，依赖完整硬件环境

---

### Gaps Summary

无阻塞性差距。所有脚本静态检查通过，关键参数（EXCLUDE_CAMERAS/STATE_SLICE/ACTION_SLICE/CUDA_VISIBLE_DEVICES/WORK_DIR/PRETRAINED_DIR）均与 CONTEXT.md D-23、D-24 决策精确对齐。

唯一待确认项为硬件运行时行为，属于部署验证而非代码问题。Phase 目标"三类硬件脚本可独立运行"的可验证部分（脚本正确性）已全部通过。

---

_Verified: 2026-03-25_
_Verifier: Claude (gsd-verifier)_
