# Coding Conventions

**Analysis Date:** 2026-03-24

## Naming Patterns

**Files:**
- Lowercase with underscores: `motors_bus.py`, `lerobot_dataset.py`
- Configuration files: `configs.py`, `parser.py`
- Module files grouped by functionality: `camera.py`, `robot.py`, `policy.py`

**Functions:**
- Lowercase with underscores: `get_address()`, `sync_read()`, `create_initial_features()`
- Private functions prefixed with underscore: `_serialize_data()`, `_encode_video_worker()`, `_flush_metadata_buffer()`
- Abstract methods marked with `@abc.abstractmethod` decorator

**Variables:**
- Lowercase with underscores for local and module-level variables: `ctrl_table`, `model_ctrl_table`
- Type aliases use PascalCase: `NameOrID`, `Value`, `NDArray`
- Constants in UPPERCASE: `DEFAULT_CHUNK_SIZE`, `DEFAULT_VIDEO_FILE_SIZE_IN_MB`

**Types:**
- Classes use PascalCase: `Camera`, `MotorsBusBase`, `LeRobotDataset`
- Enum classes inherit from `str` and `Enum`: `MotorNormMode(str, Enum)`
- Dataclass fields use lowercase: `@dataclass class Motor: id: int`

## Code Style

**Formatting:**
- Tool: Ruff (configured in `pyproject.toml`)
- Line length: 110 characters
- Quote style: Double quotes (`"string"`)
- Indent style: 4 spaces
- Skip magic trailing comma: False

**Linting:**
- Tool: Ruff (astral-sh/ruff-pre-commit v0.14.1)
- Selected rules: E, W, F, I, B, C4, T20, N, UP, SIM
- Ignored rules: E501 (line too long), T201/T203 (print statements), B008 (function call in defaults)
- Per-file ignores: `__init__.py` ignores F401, F403 (unused imports)
- Special handling: `src/lerobot/policies/wall_x/**` has suppressed rules for original Qwen code

**Pre-commit hooks:**
- File size check: 1024 KB limit
- Debug statement detection
- Merge conflict detection
- YAML/TOML validation
- End-of-file fixer (excluding URDF assets)
- Trailing whitespace removal
- Typo detection via typos hook
- Security scanning via bandit and gitleaks

## Import Organization

**Order:**
1. Standard library imports (e.g., `import logging`, `import abc`)
2. Third-party imports (e.g., `import torch`, `import numpy as np`)
3. Local package imports (e.g., `from lerobot.motors.motors_bus import Motor`)

**Formatting:**
- Use `from __future__ import annotations` at top of file for forward references
- Combine relative imports: `from .configs import CameraConfig`
- Type hints after line: `from typing import Any, Protocol, TypeAlias, TypeVar`

**Path Aliases:**
- Known first-party: `lerobot` (configured in ruff.lint.isort)
- Import directly: `from lerobot.motors.motors_bus import Motor`
- No path aliasing symbols used

## Error Handling

**Custom Exceptions:**
- Location: `src/lerobot/utils/errors.py`
- Base classes: Inherit from standard exceptions (e.g., `ConnectionError`)
- Pattern:
  ```python
  class DeviceNotConnectedError(ConnectionError):
      """Exception raised when device is not connected."""
      def __init__(self, message="Default message"):
          self.message = message
          super().__init__(self.message)
  ```

**Error Raising:**
- Use descriptive messages with context: `raise KeyError(f"Address for '{data_name}' not found in {model} control table.")`
- Include variable values using f-strings: `raise IndexError(f"Episode index {ep_index} out of range. Episodes: {len(self.episodes)}")`
- Specific exception types for specific conditions: `KeyError` for missing keys, `NotImplementedError` for unsupported operations
- For NotImplementedError, include what operation is not supported and why

**Error Recovery:**
- Try/except blocks catch specific exceptions first
- Use `except (FileNotFoundError, NotADirectoryError)` for multiple related exceptions
- Suppress expected warnings with `# nosec B110` comment for security scanner when catching bare `Exception`
- Cleanup in finally or use context managers

## Logging

**Framework:** Python's standard `logging` module

**Setup Pattern:**
```python
import logging
logger = logging.getLogger(__name__)
```

**Log Levels:**
- `logger.debug()`: Fine-grained diagnostic information (timing, detailed state)
- `logger.info()`: Confirmation that things are working (connection status, initialization)
- `logger.warning()`: Something unexpected happened (fallback actions, deprecated usage)
- `logger.error()`: Serious problem (computation failures, convergence errors)

**Examples:**
- `logger.info(f"{self} connected.")` - Connection status
- `logger.warning(f"Device '{self.device}' is not available. Switching to '{auto_device}'.")` - Fallback action
- `logger.error(f"{CONFIG_NAME} not found in {Path(model_id).resolve()}")` - File not found
- `logger.debug(f"{self} read action: {dt_ms:.1f}ms")` - Timing information

## Comments

**When to Comment:**
- Explain non-obvious logic or assumptions
- Document workarounds and TODOs with issue references
- Mark suppressed linting rules with explanation

**Comment Style:**
```python
# Single-line comment for simple statements
# This explains what the code below does

# TODO(aliberts): Add block noqa when feature below is available
# https://github.com/astral-sh/ruff/issues/3711

# nosec B110 - Intentional bare Exception catch for cleanup
```

**DOC Patterns (Google-style):**
- Use triple-quoted strings for docstrings
- Sections: `Args:`, `Returns:`, `Raises:` (optional)
- Type hints in function signatures, not in docstrings
- Example:
  ```python
  def get_address(model_ctrl_table: dict[str, dict], model: str, data_name: str) -> tuple[int, int]:
      """Get address and byte count for a data field in motor control table.

      Args:
          model_ctrl_table: Dictionary mapping model names to control tables.
          model: Motor model name.
          data_name: Name of the data field.

      Returns:
          Tuple of (address, num_bytes).

      Raises:
          KeyError: If model or data_name not found in control table.
      """
  ```

## Function Design

**Size:**
- Keep functions focused and reasonably sized
- Extract helper functions for repeated patterns
- Private methods prefixed with `_` for internal implementation details

**Parameters:**
- Use keyword-only arguments after `*` for clarity: `def save(..., allow_patterns: str | None = None, *, force_cache_sync: bool = False)`
- Type hints required for all parameters and return values
- Default values use `None` or sensible type-specific defaults

**Return Values:**
- Type hints required
- Return tuples for multiple values: `tuple[int, int]`
- Use `None` explicitly when no value returned
- Context managers use `None` from `__enter__` or return self

## Module Design

**Exports:**
- All public classes and functions are importable from module
- Private implementation details use `_` prefix (e.g., `_serialize_data`)

**Barrel Files (\_\_init\_\_.py):**
- Import and re-export public API: `from .camera import Camera`
- Keep minimum content, delegate to submodules
- Document what's exported from the module

**Abstract Base Classes:**
- Use `abc.ABC` and `@abc.abstractmethod` decorator
- Define protocol-level interfaces
- Example: `MotorsBusBase` defines interface all motor bus implementations must follow

## Code Organization Patterns

**Class Definition:**
- Class docstring immediately after class declaration
- Instance attributes initialized in `__init__`
- Properties use `@property` decorator with docstrings
- Abstract methods clearly marked
- Context manager support via `__enter__`/`__exit__`

**Type Annotations:**
- Python 3.10+ style: `dict[str, int]` not `Dict[str, int]`
- Union types: `str | int` not `Union[str, int]`
- Optional: `str | None` not `Optional[str]`
- Forward references use `from __future__ import annotations`

## Development Configuration

**Type Checking:**
- Tool: mypy (configured in `pyproject.toml`)
- Enabled selectively: `lerobot.envs`, `lerobot.configs`, `lerobot.optim`, `lerobot.model`, `lerobot.cameras`, `lerobot.motors`, `lerobot.transport`
- Other modules: `ignore_errors = true` (gradual typing)
- Config module has strictest settings: `disallow_untyped_defs`, `disallow_incomplete_defs`, `check_untyped_defs`

**Security:**
- Bandit (PyCQA/bandit v1.8.6) checks in pre-commit
- Gitleaks detection for secrets
- Skips: B101 (assert), B311 (pickle), B404 (subprocess), B603/B615 (shell injection) - these are expected in robotics context

---

*Convention analysis: 2026-03-24*
