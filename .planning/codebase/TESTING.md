# Testing Patterns

**Analysis Date:** 2026-03-24

## Test Framework

**Runner:**
- pytest 8.1.0 - 9.0.0
- Config file: None (uses default pytest discovery in `tests/` directory)
- Plugins registered in `tests/conftest.py`:
  - `tests.fixtures.dataset_factories`
  - `tests.fixtures.files`
  - `tests.fixtures.hub`
  - `tests.fixtures.optimizers`

**Assertion Library:**
- pytest built-in assertions (`assert` statement)
- `pytest.raises()` for exception testing
- Custom assertion helpers: `assert_contract_is_typed()`, `assert_same_address()`

**Additional Testing Tools:**
- pytest-timeout: Timeout protection for tests
- pytest-cov: Coverage reporting
- mock-serial: Serial port mocking (non-Windows)

**Run Commands:**
```bash
# Run all tests
pytest

# Run specific test
pytest tests/motors/test_motors_bus.py::test_get_ctrl_table

# Run with timeout (from pre-commit conftest)
pytest --timeout=300

# Coverage report
pytest --cov=lerobot --cov-report=html

# Watch mode (requires pytest-watch plugin, not in requirements)
```

## Test File Organization

**Location:**
- Parallel structure: `tests/` mirrors `src/lerobot/` structure
- Example: `src/lerobot/motors/motors_bus.py` → `tests/motors/test_motors_bus.py`
- Fixture modules in `tests/fixtures/` directory
- Mock modules in `tests/mocks/` directory

**Naming:**
- Test files: `test_<module_name>.py`
- Test functions: `test_<functionality_being_tested>()`
- Test classes: `Test<ClassName>` (optional, not commonly used)

**Structure:**
```
tests/
├── cameras/
│   ├── test_opencv.py
│   ├── test_realsense.py
│   └── test_reachy2_camera.py
├── datasets/
│   ├── test_datasets.py
│   ├── test_image_writer.py
│   └── ...
├── motors/
│   ├── test_motors_bus.py
│   ├── test_dynamixel.py
│   └── ...
├── fixtures/
│   ├── dataset_factories.py
│   ├── files.py
│   ├── hub.py
│   └── optimizers.py
├── mocks/
│   ├── mock_robot.py
│   ├── mock_motors_bus.py
│   └── ...
├── conftest.py
└── utils.py
```

## Test Structure

**Suite Organization (pytest conventions):**
```python
# Standard test module structure
#!/usr/bin/env python

# Copyright header

import pytest
from unittest.mock import patch, MagicMock

# Test fixtures
@pytest.fixture
def dummy_motors() -> dict[str, Motor]:
    return {
        "dummy_1": Motor(1, "model_2", MotorNormMode.RANGE_M100_100),
        "dummy_2": Motor(2, "model_3", MotorNormMode.RANGE_M100_100),
    }

# Test functions
def test_get_ctrl_table():
    """Test control table retrieval."""
    model = "model_1"
    ctrl_table = get_ctrl_table(DUMMY_MODEL_CTRL_TABLE, model)
    assert ctrl_table == DUMMY_CTRL_TABLE_1

def test_get_ctrl_table_error():
    """Test error handling for missing control table."""
    model = "model_99"
    with pytest.raises(KeyError, match=f"Control table for {model=} not found."):
        get_ctrl_table(DUMMY_MODEL_CTRL_TABLE, model)
```

**Patterns:**
- One test function per behavior being tested
- Descriptive test names following `test_<what_is_being_tested>` pattern
- Docstrings optional but recommended for clarity
- Imports at top, tests grouped logically
- Fixtures used for setup; teardown via fixture cleanup

## Mocking

**Framework:** `unittest.mock` from Python standard library

**Common Patterns:**

**1. Patching external dependencies:**
```python
from unittest.mock import patch

@pytest.fixture(autouse=True)
def patch_opencv_videocapture():
    """Automatically patches cv2.VideoCapture for all tests."""
    module_path = OpenCVCamera.__module__
    target = f"{module_path}.cv2.VideoCapture"
    with patch(target, new=MockLoopingVideoCapture):
        yield
```

**2. Creating mock objects:**
```python
from unittest.mock import MagicMock, patch

class MockPolicy:
    """Minimal mock returning deterministic values."""
    class _Config:
        robot_type = "dummy_robot"

    def predict_action_chunk(self, observation: dict[str, torch.Tensor]) -> torch.Tensor:
        batch_size = len(observation[OBS_STATE])
        return torch.zeros(batch_size, 20, 6)
```

**3. In-test patching:**
```python
with patch("module.function") as mock_func:
    mock_func.return_value = expected_value
    # Test code that calls module.function()
```

**What to Mock:**
- External hardware interfaces: camera connections, motor buses
- File I/O: use temporary directories with `tmp_path` fixture
- Network calls: API requests, downloads
- Time-consuming operations: model inference, video encoding
- System dependencies: serial ports, device detection

**What NOT to Mock:**
- Core business logic being tested
- Data transformation functions
- Configuration loading (use real config files or factories)
- Torch operations (use real tensors for correctness)
- Dataset access patterns (use real datasets or factories)

**Mock Location:**
- Reusable mocks: `tests/mocks/mock_*.py` files
- Test-specific mocks: Defined in test file or conftest
- Example: `tests/mocks/mock_motors_bus.py` provides `MockMotorsBus`

## Fixtures and Factories

**Test Data:**

**Fixture Pattern (reusable test components):**
```python
@pytest.fixture
def image_dataset(tmp_path, empty_lerobot_dataset_factory):
    """Create a test dataset with image features."""
    features = {
        "image": {
            "dtype": "image",
            "shape": DUMMY_CHW,
            "names": ["channels", "height", "width"],
        }
    }
    return empty_lerobot_dataset_factory(root=tmp_path / "test", features=features)

@pytest.fixture(autouse=True)
def patch_builtins_input(monkeypatch):
    """Auto-applied fixture patching stdin."""
    def print_text(text=None):
        if text is not None:
            print(text)
    monkeypatch.setattr("builtins.input", print_text)
```

**Factory Pattern (complex object creation):**
```python
# Fixture that returns a factory function
@pytest.fixture
def policy_feature_factory():
    """PolicyFeature factory"""
    def _pf(ft: FeatureType, shape: tuple[int, ...]) -> PolicyFeature:
        return PolicyFeature(type=ft, shape=shape)
    return _pf

# Usage in test
def test_something(policy_feature_factory):
    feature = policy_feature_factory(FeatureType.FLOAT, (4,))
```

**Location:**
- Global fixtures: `tests/conftest.py`
- Module-specific fixtures: `tests/<module>/conftest.py` (auto-discovered)
- Fixture collections: `tests/fixtures/*.py` registered in main conftest via `pytest_plugins`

**Key Fixtures:**
- `tmp_path`: Temporary directory for each test (pytest built-in)
- `monkeypatch`: Patching and environment modification (pytest built-in)
- `lerobot_dataset_factory`: Creates test datasets
- `empty_lerobot_dataset_factory`: Creates empty datasets with custom features
- `policy_feature_factory`: Creates policy feature objects

## Coverage

**Requirements:** No enforced minimum (coverage checks not configured)

**View Coverage:**
```bash
pytest --cov=lerobot --cov-report=html
# Results in htmlcov/index.html
```

**Coverage Configuration:**
- Tool: pytest-cov
- Target: `lerobot` package
- Report format: HTML (human-readable), can add `--cov-report=term-missing` for terminal

## Test Types

**Unit Tests:**
- Scope: Single function or method behavior
- Location: `tests/<module>/` parallel to source
- Examples: `tests/motors/test_motors_bus.py::test_get_address`
- Approach: Mock external dependencies, test return values and exceptions
- Isolation: Each test is independent

**Integration Tests:**
- Scope: Multiple components working together
- Location: Same test files as unit tests
- Examples: `tests/datasets/test_datasets.py::test_dataset_initialization`
- Approach: Use real fixtures, partial mocking (mock hardware, use real logic)
- Setup: Factory fixtures for complex test data

**E2E Tests:**
- Framework: Not explicitly used
- Alternative: Some tests marked with `@pytest.mark.skip("Requires internet access")` or `@require_package()`
- Hardware tests: `@require_x86_64_kernel` marker for architecture-specific tests

**Markers and Skip Conditions:**
```python
@pytest.mark.skip("TODO after fix multidataset")  # Explicitly skip
@pytest.mark.skip("Requires internet access")     # Conditional skip

@pytest.mark.parametrize(
    ("robot_type", "teleop_type"),
    [
        ("bi_piper_follower", "bi_piper_leader"),
        ("so101_follower", "so101_leader"),
    ],
)
def test_sanity_check(robot_type, teleop_type):
    """Parameterized test for multiple input combinations."""
```

## Common Patterns

**Async Testing:**
```python
# Pytest doesn't have built-in async support in test discovery
# Use explicit async test runners if needed, or test async code synchronously
# Example: test the return value of async operations
import asyncio

def test_async_operation():
    result = asyncio.run(my_async_function())
    assert result == expected_value
```

**Error Testing:**
```python
# Standard pytest.raises pattern
def test_get_address_error():
    """Test error handling."""
    model = "model_1"
    data_name = "Lock"
    with pytest.raises(KeyError, match=f"Address for '{data_name}' not found in {model} control table."):
        get_address(DUMMY_MODEL_CTRL_TABLE, "model_1", data_name)

# With regex matching
import re
with pytest.raises(
    NotImplementedError,
    match=re.escape("At least two motor models use a different address"),
):
    assert_same_address(...)
```

**Parametrized Testing:**
```python
@pytest.mark.parametrize(
    ("input_value", "expected"),
    [
        (1, 2),
        (2, 4),
        (3, 6),
    ],
)
def test_double(input_value, expected):
    """Test with multiple input combinations."""
    assert double(input_value) == expected
```

**Context Manager Testing:**
```python
def test_camera_context_manager(tmp_path):
    """Test that camera connects on entry and disconnects on exit."""
    with patch_opencv_videocapture():
        with OpenCVCamera(config) as camera:
            # Camera is connected here
            assert camera.is_connected
        # Camera is disconnected after exiting context
```

**Fixture Dependency:**
```python
@pytest.fixture
def dataset_with_metadata(tmp_path, lerobot_dataset_factory):
    """Fixture depending on another fixture."""
    # lerobot_dataset_factory is automatically injected
    return lerobot_dataset_factory(root=tmp_path, total_episodes=10)

def test_with_dependencies(dataset_with_metadata):
    """Test using dependent fixture."""
    assert len(dataset_with_metadata.episodes) == 10
```

## Test Configuration Collection

**Pytest Hook:**
```python
def pytest_collection_finish():
    """Called after all tests are collected."""
    print(f"\nTesting with {DEVICE=}")
```

**Environment Detection:**
```python
# tests/utils.py provides helpers
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

def require_x86_64_kernel(test_func):
    """Decorator to skip tests on ARM platforms."""
    # Implementation checks platform before running test
```

---

*Testing analysis: 2026-03-24*
