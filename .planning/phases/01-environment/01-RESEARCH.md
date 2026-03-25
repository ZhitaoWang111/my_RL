# Phase 1: 数据兼容性检查 - Research

**Researched:** 2026-03-25
**Domain:** LeRobot dataset format (v2.1 vs v3.0), Git LFS detection, 3-stage training pipeline field requirements
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

| 属性 | fold_cloth | Kai0_dataset |
|------|-----------|--------------|
| 路径 | `/media/wzt/cfy/pi-finetune/fold_cloth` | `/media/wzt/cfy/pi-finetune/Kai0_dataset/Task_A/base` |
| 版本 | v3.0 | v2.1 |
| 机器人 | bi_piper_follower | agilex |
| Episodes | 50 | 3,055 |

- **D-01**: Kai0 目标用途：全流水线预训练（value-train → value-infer → policy-train），产出 checkpoint 后再用 fold_cloth fine-tune
- **D-02**: 产出形式：`Evo-RL/scripts/check_datasets.py`，运行即输出兼容性报告
- **D-03**: 脚本支持两种调用方式：(1) 默认硬编码两个数据集路径；(2) `--datasets /path1 /path2 [...]`
- **D-04**: 不加载任何模型，不读取 parquet 内容（只读 `meta/info.json` 和 `meta/stats.json`），确保运行速度快
- **D-05**: 版本不兼容：Kai0 v2.1 需迁移脚本
- **D-06**: Git LFS 指针：Kai0 parquet 文件需 `git lfs pull`
- **D-07**: 相机名称差异：无重叠，需后续 Phase 决策映射策略
- **D-08**: 无命名字段：Kai0 feature `names` 为 null
- **D-09**: 无 EndEffector 字段：Kai0 缺少 `action_ee` 和 `observation.state_ee`
- **D-10**: 报告输出格式由 Claude 设计，要求清晰显示每个数据集状态（✓/⚠️/✗），阻塞项有编号和修复命令

### Claude's Discretion

- 报告输出格式（layout、color、heading 风格）

### Deferred Ideas (OUT OF SCOPE)

- `download_weights.sh` — 下载预训练权重
- `rsync_to_a100.sh` — 代码/权重迁移到 A100
- `verify_env.py` — 环境验证脚本
- `setup_guide.md` — 环境搭建文档
- Kai0 v2.1 → v3.0 实际格式转换
- Git LFS pull 实际执行
- 相机名称映射策略设计
- Kai0 EndEffector 字段补充
</user_constraints>

---

<phase_requirements>
## Phase Requirements

NOTE: The formal requirement IDs (ENV-01, ENV-02, ENV-03) in REQUIREMENTS.md refer to the old environment setup focus. Phase 1 has been redirected per CONTEXT.md. The actual deliverable is `check_datasets.py`.

| ID | Description | Research Support |
|----|-------------|------------------|
| DATA-CHECK | Create `Evo-RL/scripts/check_datasets.py` that checks compatibility of fold_cloth (v3.0) and Kai0_dataset (v2.1) with the 3-stage RL training pipeline | All sections below |
</phase_requirements>

---

## Summary

Phase 1 delivers a single Python script (`Evo-RL/scripts/check_datasets.py`) that reads only `meta/info.json` and `meta/stats.json` from each dataset and produces a structured compatibility report. No model loading, no parquet data reading — just metadata inspection.

Research has been conducted by reading the actual dataset files on disk, the LeRobot dataset loading code (`lerobot_dataset.py`, `utils.py`, `backward_compatibility.py`), the conversion script (`v30/convert_dataset_v21_to_v30.py`), and the 3-stage training scripts (`train_pen_4090.sh`, `resume_cloth_round1_4090.sh`, `lerobot_value_infer.py`). All findings are HIGH confidence from first-party source code and live filesystem inspection.

The central finding is that Kai0_dataset has **four independent blocking issues** (LFS pointers, v2.1 format, missing stats.json, v3.0 file-naming assumed by `value_infer`). Each must be resolved before Kai0 can enter any stage of the pipeline. fold_cloth is fully ready.

**Primary recommendation:** Write `check_datasets.py` as a standalone script with zero heavy dependencies (only `json`, `pathlib`, `argparse`). Detect issues from `meta/info.json` content and filesystem-level byte-sniffing of parquet files. Output a human-readable console report with numbered blockers and exact fix commands.

---

## Standard Stack

### Core (script dependencies)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `json` | stdlib | Parse `meta/info.json` and `meta/stats.json` | Built-in, zero cost |
| `pathlib` | stdlib | Filesystem path operations | Already used across all LeRobot code |
| `argparse` | stdlib | `--datasets` CLI flag | Standard CLI pattern in this repo |

**No external dependencies required.** The script must run with Python 3.10 stdlib only. Do NOT import `pandas`, `pyarrow`, or `lerobot` — those add boot time and may not be installed in all environments.

### Optional (for richer terminal output)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `termcolor` | 3.1.0 | Colored ✓/⚠️/✗ status markers | Already in requirements; use if available, fallback to plain text |

**Installation:** No new packages needed. `termcolor` is already a project dependency per CLAUDE.md.

---

## Architecture Patterns

### Recommended Script Structure

```
Evo-RL/scripts/check_datasets.py
```

```python
# Top-level structure
DEFAULT_DATASETS = [
    "/media/wzt/cfy/pi-finetune/fold_cloth",
    "/media/wzt/cfy/pi-finetune/Kai0_dataset/Task_A/base",
]
CODEBASE_VERSION = "v3.0"     # Must match lerobot_dataset.py line 81
LFS_MAGIC = b"version https://git-lfs.github.com"

def check_dataset(root: Path) -> dict:      # returns structured result
def is_lfs_pointer(path: Path) -> bool:     # byte-sniff first 40 bytes
def check_lfs_status(root: Path) -> dict:   # probe parquet files
def format_report(results: list[dict]):     # console output
def main():                                  # argparse + orchestration
```

### Pattern 1: Metadata-Only Inspection

**What:** Read only `meta/info.json` and check `meta/stats.json` existence. Never open parquet files with pandas/pyarrow.

**When to use:** Always — D-04 explicitly prohibits model loading and parquet content reading.

**Implementation:**
```python
# Source: lerobot/datasets/utils.py lines 288-302
import json
from pathlib import Path

def load_info(root: Path) -> dict:
    with open(root / "meta" / "info.json") as f:
        info = json.load(f)
    for ft in info["features"].values():
        ft["shape"] = tuple(ft["shape"])
    return info
```

The check script should replicate this minimal pattern (without importing lerobot) to stay dependency-free.

### Pattern 2: LFS Pointer Detection

**What:** Read the first 40 bytes of a parquet file. Real parquet files begin with `PAR1` magic bytes. LFS pointer files begin with ASCII `version https://git-lfs.github.com`.

**When to use:** For every dataset — check one representative parquet file from each dataset to determine LFS status.

```python
LFS_MAGIC = b"version https://git-lfs.github.com"

def is_lfs_pointer(path: Path) -> bool:
    try:
        with open(path, "rb") as f:
            return f.read(len(LFS_MAGIC)) == LFS_MAGIC
    except (OSError, PermissionError):
        return False
```

**Verified:** fold_cloth `data/chunk-000/file-000.parquet` = 1,990,271 bytes (real data). Kai0 `data/chunk-000/episode_000000.parquet` = 131 bytes (LFS pointer). Both video files in Kai0 are also LFS pointers.

### Pattern 3: Version Compatibility Check

**What:** Read `info["codebase_version"]` and compare major version against `"v3.0"`.

**Source logic:** `lerobot/datasets/backward_compatibility.py` — `BackwardCompatibilityError` is raised when `v_check.major < v_current.major`. v2.1 has major=2, v3.0 has major=3 → incompatible.

```python
import packaging.version

def check_version(info: dict) -> tuple[bool, str]:
    ver = packaging.version.parse(info["codebase_version"])
    current = packaging.version.parse(CODEBASE_VERSION)
    if ver.major < current.major:
        return False, f"v{ver} → must migrate to {CODEBASE_VERSION}"
    return True, info["codebase_version"]
```

Note: `packaging` is already a project dependency (listed in requirements as `packaging 25.0`).

### Pattern 4: Required Field Check

**What:** Inspect `info["features"]` for the minimum fields the 3-stage pipeline requires.

**Source:** `lerobot/datasets/utils.py` line 73 — `DEFAULT_FEATURES`. `train_pen_4090.sh` — pipeline requires `action`, `observation.state`, at least one `observation.images.*`.

```python
REQUIRED_FIELDS = {"action", "observation.state"}  # at least one camera checked separately

def check_required_fields(features: dict) -> list[str]:
    missing = []
    for field in REQUIRED_FIELDS:
        if field not in features:
            missing.append(field)
    cameras = [k for k, v in features.items()
               if k.startswith("observation.images.") and v["dtype"] in ("video", "image")]
    if not cameras:
        missing.append("observation.images.* (at least one camera)")
    return missing
```

### Pattern 5: Stage 2 Write-Back Compatibility Check

**What:** `lerobot_value_infer.py` line 359 globs `data/chunk-*/file-*.parquet`. This is the v3.0 naming convention. A v2.1 dataset (`data/chunk-000/episode_000000.parquet`) will return zero files and fail silently.

This is a **critical blocker** for Kai0 and must be called out explicitly in the report — even after v2.1→v3.0 conversion resolves the metadata format, the data file naming must also change.

```python
V30_DATA_PATTERN = "data/chunk-*/file-*.parquet"   # what value_infer expects
V21_DATA_PATTERN = "data/chunk-*/episode_*.parquet" # what Kai0 has

def check_data_file_naming(root: Path) -> dict:
    v30_files = list(root.glob(V30_DATA_PATTERN))
    v21_files = list(root.glob(V21_DATA_PATTERN))
    return {
        "v30_naming": len(v30_files) > 0,
        "v21_naming": len(v21_files) > 0,
        "v30_count": len(v30_files),
        "v21_count": len(v21_files),
    }
```

### Pattern 6: stats.json Presence Check

**What:** `lerobot_value_train.py` line 201 reads `dataset.meta.stats` and uses it for normalizer construction. `utils.py` line 329 — `load_stats()` returns `None` if `meta/stats.json` does not exist. When stats is None, the normalizer skips normalization — this may cause silent numeric issues.

- fold_cloth: `meta/stats.json` exists (28,795 bytes), covers `action`, `action_ee`, `observation.state`, `observation.state_ee`, `observation.images.*`
- Kai0: `meta/stats.json` does NOT exist (v2.1 uses `episodes_stats.jsonl` instead)

The conversion script (`convert_dataset_v21_to_v30.py`) generates per-episode stats and writes them as parquet, but does NOT generate the global `meta/stats.json`. This means after conversion, Kai0 may still lack the stats file needed for normalization. Flag this as a warning.

### Pattern 7: Named Fields Check (D-08)

**What:** Check whether `action` and `observation.state` have populated `names` lists. Named fields allow `train_state_slice` and `train_action_slice` to be human-readable; unnamed fields require numeric slicing.

```python
def check_named_fields(features: dict) -> dict:
    result = {}
    for field in ("action", "observation.state"):
        if field in features:
            result[field] = features[field].get("names") is not None
    return result
```

### Anti-Patterns to Avoid

- **Importing lerobot:** The script must NOT `from lerobot.datasets import ...`. This adds boot time and may fail outside the conda env.
- **Opening parquet with pandas/pyarrow:** Violates D-04 and will crash on LFS pointer files with a cryptic error.
- **Checking only one parquet file for LFS:** Check one file per dataset; document which file was checked.
- **Failing silently on missing meta/info.json:** Catch `FileNotFoundError` and report it as a blocker with the specific path.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Version parsing | Custom string comparison | `packaging.version.parse()` | Handles edge cases like `v3.0 > v2.1` correctly; already a project dependency |
| LFS detection | File size heuristic | Byte-sniff first 40 bytes | Size can vary; magic bytes are definitive |
| Feature extraction from info.json | Recursive dict walker | Direct `info["features"]` access | info.json structure is flat by design in both v2.1 and v3.0 |

**Key insight:** The script is intentionally thin. All heavy validation (schema correctness, data loading) is already in the LeRobot dataset loading code — the check script only needs to answer "will this dataset get past `load_metadata()` and `_write_columns_in_place()`?"

---

## Common Pitfalls

### Pitfall 1: LFS Pointer Crash in Parquet Check

**What goes wrong:** Code calls `pq.read_metadata(path)` or `pd.read_parquet(path)` on a 131-byte LFS pointer file. pyarrow raises `ArrowInvalid: Not a Parquet file`.

**Why it happens:** LFS pointer files look like regular files at the OS level but contain ASCII metadata, not parquet data.

**How to avoid:** Always byte-sniff before reading. The byte-sniff should happen before any parquet-related function call.

**Warning signs:** Any file under 200 bytes in the `data/` directory is almost certainly an LFS pointer.

### Pitfall 2: Conversion Script Path Convention

**What goes wrong:** Running `convert_dataset_v21_to_v30.py --root=/media/wzt/cfy/pi-finetune/Kai0_dataset/Task_A/base --repo-id=wzt/kai0` creates the output at `Path(root) / repo_id` = `/media/wzt/cfy/pi-finetune/Kai0_dataset/Task_A/base/wzt/kai0`, NOT in-place.

**Why it happens:** Line 472: `root = HF_LEROBOT_HOME / repo_id if root is None else Path(root) / repo_id`. The script appends `repo_id` to the root path.

**How to avoid:** The check report should document the exact invocation with `--root` set to the **parent** of the dataset directory:

```bash
python -m lerobot.datasets.v30.convert_dataset_v21_to_v30 \
    --repo-id=wzt/Kai0 \
    --root=/media/wzt/cfy/pi-finetune/Kai0_dataset/Task_A \
    --push-to-hub=false
```

This places the converted dataset at `/media/wzt/cfy/pi-finetune/Kai0_dataset/Task_A/Kai0` (not `base`). The report must clarify this path behavior.

### Pitfall 3: LFS Pull Order Dependency

**What goes wrong:** User runs `git lfs pull` in the Kai0_dataset directory but the conversion script is then run while network is unavailable or LFS is incomplete. The conversion script calls `get_parquet_file_size_in_mb()` which uses pyarrow to read parquet metadata — this will fail on incomplete LFS data.

**Why it happens:** `convert_data()` line 215 calls `get_parquet_file_size_in_mb(ep_path)` which opens the parquet file.

**How to avoid:** The report must specify the correct fix order: (1) `git lfs pull` first, (2) verify LFS completion by checking file sizes, (3) then run conversion.

### Pitfall 4: Missing stats.json After Conversion

**What goes wrong:** The `convert_dataset_v21_to_v30.py` conversion script writes per-episode stats as parquet files but does NOT generate a global `meta/stats.json`. The `load_stats()` function returns `None`. Training proceeds without normalization, causing unstable training or NaN losses.

**Why it happens:** The v3.0 format moved from a single `stats.json` to per-episode stats in parquet. The value_train script reads `dataset.meta.stats` (line 201) and uses it only for the normalizer — a None value is silently accepted.

**How to avoid:** The check report should flag stats as a WARNING (not a blocker) for Kai0 post-conversion, with a recommendation to compute stats separately after conversion.

### Pitfall 5: value_infer Expects v3.0 File Naming Even After Format Conversion

**What goes wrong:** Even if Kai0 metadata is upgraded to v3.0 format, the `_write_columns_in_place()` function in `lerobot_value_infer.py` line 359 globs `data/chunk-*/file-*.parquet`. If data files still use v2.1 naming (`episode_000000.parquet`), the glob returns zero files and the ACP annotation step silently writes nothing.

**Why it happens:** The glob pattern is hardcoded to the v3.0 file naming scheme. The conversion script handles this — but only if it is run in full, including the `convert_data()` step.

**How to avoid:** The check report must distinguish between "metadata converted" and "data files renamed to v3.0 convention" as two separate requirements.

### Pitfall 6: Camera Names in info.json Not Updated After Mapping

**What goes wrong:** After mapping Kai0 camera names (e.g., `top_head` → `left_top`) in post-conversion, the `info.json` feature keys must also be updated. If `info.json` still lists old camera names but the video files are renamed, `load_info()` will construct wrong video paths.

**Why it happens:** Camera name mapping requires coordinated rename of (1) `info.json` feature keys, (2) `videos/{old_camera}/` directories.

**How to avoid:** Flag camera name mismatch in the report as a WARNING for future Phase work — not a current blocker since mapping strategy is deferred.

---

## Dataset Facts (Verified from Live Filesystem)

### fold_cloth (v3.0 — Compatible)

| Property | Value | Source |
|----------|-------|--------|
| `codebase_version` | `"v3.0"` | `meta/info.json` |
| `robot_type` | `"bi_piper_follower"` | `meta/info.json` |
| `total_episodes` | 50 | `meta/info.json` |
| `total_frames` | 73,445 | `meta/info.json` |
| `fps` | 30 | `meta/info.json` |
| `action` shape | [14], named | `meta/info.json` |
| `observation.state` shape | [14], named | `meta/info.json` |
| Cameras | `left_wrist_left`, `left_top`, `right_wrist_right` | `meta/info.json` |
| `observation.state_ee` | present, shape [14] | `meta/info.json` |
| `action_ee` | present, shape [14] | `meta/info.json` |
| `meta/stats.json` | present (28,795 bytes) | filesystem |
| `meta/episodes/` | present (parquet, not jsonl) | filesystem |
| `meta/tasks.parquet` | present | filesystem |
| `data/chunk-000/file-000.parquet` | 1,990,271 bytes (real data) | filesystem |
| Videos | `videos/{camera}/chunk-000/file-N.mp4` (v3.0 layout) | filesystem |
| LFS status | Real data (not LFS pointer) | byte-sniff verified |

### Kai0_dataset (v2.1 — Incompatible)

| Property | Value | Source |
|----------|-------|--------|
| `codebase_version` | `"v2.1"` | `meta/info.json` |
| `robot_type` | `"agilex"` | `meta/info.json` |
| `total_episodes` | 3,055 | `meta/info.json` |
| `total_frames` | 3,362,369 | `meta/info.json` |
| `fps` | 30 | `meta/info.json` |
| `action` shape | [14], names=null | `meta/info.json` |
| `observation.state` shape | [14], names=null | `meta/info.json` |
| Cameras | `top_head`, `hand_left`, `hand_right` | `meta/info.json` |
| `observation.state_ee` | ABSENT | `meta/info.json` |
| `action_ee` | ABSENT | `meta/info.json` |
| `meta/stats.json` | ABSENT (v2.1 uses `episodes_stats.jsonl`) | filesystem |
| `meta/episodes.jsonl` | present (3,055 lines) | filesystem |
| `meta/tasks.jsonl` | present (1 task: "flat the cloth") | filesystem |
| `data/chunk-000/episode_000000.parquet` | 131 bytes (LFS pointer) | filesystem |
| Videos | `videos/chunk-000/{camera}/episode_N.mp4` (v2.1 layout) | filesystem |
| LFS status | LFS pointers (parquet + video both) | byte-sniff verified |

---

## 3-Stage Training Pipeline Requirements

### Stage 1: value-train (lerobot-value-train)

**Dataset requirements verified from `lerobot_value_train.py` and `train_pen_4090.sh`:**

| Requirement | fold_cloth | Kai0 | Notes |
|-------------|-----------|------|-------|
| `codebase_version = "v3.0"` | ✓ | ✗ (v2.1 → BackwardCompatibilityError) | Hard blocker |
| `meta/info.json` exists | ✓ | ✓ | OK |
| `meta/stats.json` exists | ✓ | ✗ | Soft warning — training degrades without normalization |
| `action` feature present | ✓ | ✓ | OK |
| `observation.state` feature present | ✓ | ✓ | OK |
| At least one camera feature | ✓ (3 cameras) | ✓ (3 cameras) | OK |
| Parquet files readable (not LFS) | ✓ | ✗ | Hard blocker |
| `observation.state_ee` + `action_ee` | ✓ | ✗ | Only needed if `--train_action_space=ee`; soft blocker |

### Stage 2: value-infer (lerobot-value-infer)

**Additional requirements beyond Stage 1:**

| Requirement | fold_cloth | Kai0 | Notes |
|-------------|-----------|------|-------|
| Data files at `data/chunk-*/file-*.parquet` | ✓ | ✗ (v2.1 uses `episode_*.parquet`) | Hard blocker — value_infer line 359 glob |
| Parquet files writable (in-place annotation) | ✓ | ✗ (LFS pointers) | Hard blocker |

### Stage 3: policy-train (lerobot-train)

**Additional requirements beyond Stage 1+2:**

| Requirement | fold_cloth | Kai0 | Notes |
|-------------|-----------|------|-------|
| `complementary_info.acp_indicator_r1` column | Added by Stage 2 | Added by Stage 2 | Written in-place by value_infer |
| `observation.state_ee` + `action_ee` | ✓ | ✗ | Only if `train_action_space=ee` |

---

## Kai0 Blocker Summary (for report output)

| # | Blocker | Impact | Fix |
|---|---------|--------|-----|
| B-01 | Git LFS pointers — parquet and video files are stubs | All 3 stages blocked | `cd /media/wzt/cfy/pi-finetune/Kai0_dataset/Task_A/base && git lfs pull` |
| B-02 | Format v2.1 — `BackwardCompatibilityError` on load | Stage 1 blocked | Run `python -m lerobot.datasets.v30.convert_dataset_v21_to_v30 --repo-id=wzt/Kai0 --root=/media/wzt/cfy/pi-finetune/Kai0_dataset/Task_A --push-to-hub=false` |
| B-03 | Data file naming v2.1 (`episode_N.parquet`) — value_infer glob finds 0 files | Stage 2 blocked | Resolved by running conversion script (converts naming as part of the process) |
| W-01 | `meta/stats.json` absent — normalizer disabled | Soft warning — degraded training | Run stats computation after conversion (separate command TBD in Phase 2) |
| W-02 | Named fields null — `names=null` for action + observation.state | Cannot use named joint slicing | Accept for pretraining; consider adding names during conversion phase |
| W-03 | No `action_ee`/`observation.state_ee` fields | `--train_action_space=ee` unavailable | Accept for pretraining (use default joint-space) |
| W-04 | Camera names differ from fold_cloth | Cannot share `--train_exclude_cameras` config | Deferred to Phase 2 — camera mapping strategy TBD |

---

## Code Examples

### Check Script Skeleton (Reference)

```python
#!/usr/bin/env python
"""Dataset compatibility check for Evo-RL 3-stage training pipeline."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

# Source: lerobot/datasets/lerobot_dataset.py line 81
CODEBASE_VERSION = "v3.0"
# Source: CONTEXT.md D-06; verified by byte-sniff of Kai0 parquet files
LFS_MAGIC = b"version https://git-lfs.github.com"

DEFAULT_DATASETS = [
    "/media/wzt/cfy/pi-finetune/fold_cloth",
    "/media/wzt/cfy/pi-finetune/Kai0_dataset/Task_A/base",
]


def is_lfs_pointer(path: Path) -> bool:
    """Return True if file is a Git LFS pointer stub."""
    try:
        with open(path, "rb") as f:
            return f.read(len(LFS_MAGIC)) == LFS_MAGIC
    except OSError:
        return False


def find_sample_parquet(root: Path) -> Path | None:
    """Find first parquet file in data/ (either v2.1 or v3.0 naming)."""
    for pattern in ("data/chunk-*/file-*.parquet", "data/chunk-*/episode_*.parquet"):
        files = sorted(root.glob(pattern))
        if files:
            return files[0]
    return None


def check_dataset(root: Path) -> dict:
    """Return structured compatibility result for one dataset."""
    result = {"root": str(root), "blockers": [], "warnings": [], "ok": []}

    info_path = root / "meta" / "info.json"
    if not info_path.exists():
        result["blockers"].append(f"meta/info.json not found at {info_path}")
        return result

    with open(info_path) as f:
        info = json.load(f)

    result["info"] = info

    # Version check (source: backward_compatibility.py)
    import packaging.version
    ver = packaging.version.parse(info.get("codebase_version", "v0.0"))
    current = packaging.version.parse(CODEBASE_VERSION)
    if ver.major < current.major:
        result["blockers"].append(
            f"[B-02] Format version {ver} — needs migration to {CODEBASE_VERSION}. "
            f"Run: python -m lerobot.datasets.v30.convert_dataset_v21_to_v30 ..."
        )
    else:
        result["ok"].append(f"codebase_version: {ver} (compatible)")

    # LFS check (source: CONTEXT.md D-06; verified on live filesystem)
    sample = find_sample_parquet(root)
    if sample is None:
        result["blockers"].append("[B-01] No parquet files found under data/")
    elif is_lfs_pointer(sample):
        result["blockers"].append(
            f"[B-01] Git LFS pointer detected ({sample.name}, {sample.stat().st_size} bytes). "
            f"Run: cd {root} && git lfs pull"
        )
    else:
        result["ok"].append(f"parquet data: real data ({sample.stat().st_size:,} bytes)")

    # v3.0 file naming check (source: lerobot_value_infer.py line 359)
    v30_files = list(root.glob("data/chunk-*/file-*.parquet"))
    v21_files = list(root.glob("data/chunk-*/episode_*.parquet"))
    if v21_files and not v30_files:
        result["blockers"].append(
            "[B-03] Data files use v2.1 naming (episode_N.parquet); "
            "lerobot-value-infer expects file-N.parquet — resolved by conversion script"
        )
    elif v30_files:
        result["ok"].append(f"data file naming: v3.0 ({len(v30_files)} files)")

    # stats.json check (source: lerobot_value_train.py line 201)
    if not (root / "meta" / "stats.json").exists():
        result["warnings"].append("[W-01] meta/stats.json missing — normalizer disabled during training")
    else:
        result["ok"].append("meta/stats.json: present")

    # Required features (source: utils.py DEFAULT_FEATURES + train script)
    features = info.get("features", {})
    for field in ("action", "observation.state"):
        if field not in features:
            result["blockers"].append(f"Required feature '{field}' missing from info.json")
        else:
            names = features[field].get("names")
            if names is None:
                result["warnings"].append(
                    f"[W-02] '{field}' has names=null — cannot use named joint slicing"
                )
            else:
                result["ok"].append(f"'{field}': present, named ({len(names)} dims)")

    cameras = [k for k, v in features.items()
               if k.startswith("observation.images.") and v.get("dtype") in ("video", "image")]
    if not cameras:
        result["blockers"].append("No camera features found in info.json")
    else:
        result["ok"].append(f"cameras: {cameras}")

    # EE fields (source: lerobot_train.py lines 208-219)
    has_ee = "observation.state_ee" in features and "action_ee" in features
    if not has_ee:
        result["warnings"].append(
            "[W-03] action_ee / observation.state_ee missing — "
            "--train_action_space=ee unavailable"
        )
    else:
        result["ok"].append("EE fields: present")

    return result
```

### Version Check Logic (from backward_compatibility.py)

```python
# Source: lerobot/datasets/backward_compatibility.py lines 42-50
# Source: lerobot/datasets/utils.py lines 481-494
import packaging.version

def is_backward_incompatible(dataset_version: str) -> bool:
    v = packaging.version.parse(dataset_version)
    current = packaging.version.parse("v3.0")
    return v.major < current.major  # v2.x < v3 → incompatible
```

### Migration Command (from backward_compatibility.py V30_MESSAGE)

```bash
# Source: lerobot/datasets/backward_compatibility.py lines 17-31
# NOTE: --root must be PARENT of the dataset directory (script appends repo-id)
# Kai0 dataset root is .../Task_A/base, so --root is .../Task_A
python -m lerobot.datasets.v30.convert_dataset_v21_to_v30 \
    --repo-id=wzt/Kai0 \
    --root=/media/wzt/cfy/pi-finetune/Kai0_dataset/Task_A \
    --push-to-hub=false
# Output: /media/wzt/cfy/pi-finetune/Kai0_dataset/Task_A/Kai0  (v3.0)
# Original renamed to: /media/wzt/cfy/pi-finetune/Kai0_dataset/Task_A/Kai0_old
```

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Python 3.10 | check_datasets.py | ✓ | System Python | — |
| `packaging` | version comparison | ✓ | 25.0 (in requirements) | Manual string split |
| `json` (stdlib) | info.json parsing | ✓ | stdlib | — |
| `pathlib` (stdlib) | file operations | ✓ | stdlib | — |
| `argparse` (stdlib) | CLI | ✓ | stdlib | — |
| fold_cloth dataset | compatibility check | ✓ | `/media/wzt/cfy/pi-finetune/fold_cloth` | — |
| Kai0_dataset | compatibility check | ✓ | `/media/wzt/cfy/pi-finetune/Kai0_dataset/Task_A/base` | — |

**Missing dependencies with no fallback:** None — the check script uses stdlib only.

**Missing dependencies with fallback:** If `packaging` is unavailable, fallback to manual version string split (`version.split(".")`) for major version comparison.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `data/chunk-000/episode_000000.parquet` | `data/chunk-000/file-000.parquet` | v2.1 → v3.0 | value_infer will miss v2.1 files silently |
| `videos/chunk-000/CAMERA/episode_N.mp4` | `videos/CAMERA/chunk-000/file-N.mp4` | v2.1 → v3.0 | Video path construction will fail on v2.1 |
| `meta/episodes.jsonl` (JSONL) | `meta/episodes/chunk-000/file-000.parquet` (Parquet) | v2.1 → v3.0 | load_episodes() fails on v2.1 format |
| `meta/tasks.jsonl` | `meta/tasks.parquet` | v2.1 → v3.0 | load_tasks() fails on v2.1 format |
| `meta/episodes_stats.jsonl` | `meta/stats.json` (global) | v2.1 → v3.0 | Global stats needed for normalizer |

**Deprecated/outdated:**
- v2.1 `LEGACY_EPISODES_PATH`, `LEGACY_EPISODES_STATS_PATH`, `LEGACY_TASKS_PATH` — defined in utils.py lines 69-71 but only used in the v30 conversion script, not in the main dataset loader.

---

## Open Questions

1. **Does `train_action_space=ee` default to `False` for Kai0 pretraining?**
   - What we know: `train_action_space` config exists in `value_train.py` (line 85), `lerobot_train.py` handles it
   - What's unclear: The default value of `train_action_space` in `ValueTrainConfig` — need to verify it's `"joint"` not `"ee"` to confirm Kai0 can pretrain without EE fields
   - Recommendation: Check `src/lerobot/configs/value_train.py` default for `train_action_space` before planning Phase 2 training

2. **stats.json after conversion — how to generate it?**
   - What we know: `convert_dataset_v21_to_v30.py` generates per-episode stats parquet, NOT global stats.json; fold_cloth has a stats.json at 28KB
   - What's unclear: Whether the `compute_stats` module (`lerobot/datasets/compute_stats.py`) can generate `stats.json` standalone
   - Recommendation: Document as a Phase 2 task; flag in report as W-01 with "TBD: `lerobot-compute-stats` or equivalent"

---

## Sources

### Primary (HIGH confidence)

- `/home/wzt/wzt/mycode/my_RL/Evo-RL/src/lerobot/datasets/lerobot_dataset.py` — CODEBASE_VERSION, load_metadata() flow
- `/home/wzt/wzt/mycode/my_RL/Evo-RL/src/lerobot/datasets/backward_compatibility.py` — BackwardCompatibilityError, V30_MESSAGE migration command
- `/home/wzt/wzt/mycode/my_RL/Evo-RL/src/lerobot/datasets/utils.py` — DEFAULT_FEATURES, load_info(), load_stats(), file path constants
- `/home/wzt/wzt/mycode/my_RL/Evo-RL/src/lerobot/datasets/v30/convert_dataset_v21_to_v30.py` — conversion process, path conventions, v2.1→v3.0 structural changes
- `/home/wzt/wzt/mycode/my_RL/Evo-RL/src/lerobot/scripts/lerobot_value_infer.py` — `_write_columns_in_place()` glob pattern (line 359), v3.0 naming dependency
- `/home/wzt/wzt/mycode/my_RL/Evo-RL/src/lerobot/scripts/lerobot_value_train.py` — stats usage (line 201), EE field validation
- `/home/wzt/wzt/mycode/my_RL/Evo-RL/src/lerobot/scripts/lerobot_train.py` — EE rename_map (lines 196-219)
- `/media/wzt/cfy/pi-finetune/fold_cloth/meta/info.json` — live v3.0 dataset metadata (verified)
- `/media/wzt/cfy/pi-finetune/Kai0_dataset/Task_A/base/meta/info.json` — live v2.1 dataset metadata (verified)
- Live filesystem byte-sniff — LFS pointer detection confirmed (131 bytes vs 1,990,271 bytes)

### Secondary (MEDIUM confidence)

- `Evo-RL/scripts/train_pen_4090.sh` — pipeline structure, `complementary_info.*` field naming convention
- `Evo-RL/scripts/resume_cloth_round1_4090.sh` — fold_cloth training context

---

## Project Constraints (from CLAUDE.md)

| Constraint | Impact on check_datasets.py |
|------------|------------------------------|
| Python 3.10, no version upgrades | Use `from __future__ import annotations`; use `str | None` not `Optional[str]` |
| Line length: 110 chars | Set linter accordingly |
| Quote style: double quotes | All strings use `"..."` |
| Naming: `lowercase_underscores` for functions | `check_dataset()`, `is_lfs_pointer()`, `find_sample_parquet()` |
| No `T201` ruff ignore → print allowed | Use `print()` freely for report output |
| Logging: use Python `logging` module for diagnostic info | `logger.info()` for step progress; `print()` for user-facing report |
| `from __future__ import annotations` at top | Required |
| Docstrings: triple-quoted, `Args:` / `Returns:` sections | Required for all public functions |

---

## Metadata

**Confidence breakdown:**
- Dataset format facts: HIGH — read directly from live filesystem and source code
- Standard stack: HIGH — stdlib only, no external dependencies
- Architecture patterns: HIGH — derived from actual training script glob patterns and loading code
- Pitfalls: HIGH — LFS verified by byte-sniff; conversion path bug verified from source code

**Research date:** 2026-03-25
**Valid until:** 2026-06-25 (stable format spec; only relevant if lerobot upstream releases v4.0)
