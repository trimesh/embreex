#!/usr/bin/env python
"""
Helper script to auto-generate type stubs (.pyi) for embreex Cython modules.
Uses `stubgen-pyx` to statically parse .pyx/.pxd files and generate .pyi stubs,
and then post-processes them to apply rich type annotations and overloads.
"""

import os
import subprocess
import sys

# Determine repository root
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
EMBREEX_DIR = os.path.join(REPO_ROOT, "embreex")


def get_stubgen_bin() -> str:
    """Locate the stubgen-pyx executable relative to the python interpreter."""
    bin_dir = os.path.dirname(sys.executable)
    stubgen_bin = os.path.join(bin_dir, "stubgen-pyx")
    if os.path.exists(stubgen_bin):
        return stubgen_bin
    return "stubgen-pyx"


def post_process_rtcore(content: str) -> str:
    """Apply post-processing to rtcore.pyi."""
    # Normalize line endings
    content = content.replace("\r\n", "\n")

    # Add return type annotations
    content = content.replace("def __init__(self):", "def __init__(self) -> None:")
    content = content.replace("def __repr__(self):", "def __repr__(self) -> str:")
    return content


def post_process_mesh_construction(content: str) -> str:
    """Apply post-processing to mesh_construction.pyi."""
    # Normalize line endings
    content = content.replace("\r\n", "\n")

    # Import numpy.typing
    content = content.replace(
        "import numpy as np", "import numpy as np\nimport numpy.typing as npt"
    )

    # High-fidelity TriangleMesh constructor annotation
    target_tri = "def __init__(self, scene: rtcs.EmbreeScene, vertices: np.ndarray, indices: np.ndarray=None):"
    replacement_tri = "def __init__(self, scene: rtcs.EmbreeScene, vertices: npt.NDArray, indices: npt.NDArray | None = None) -> None:"
    content = content.replace(target_tri, replacement_tri)

    # High-fidelity ElementMesh constructor annotation
    target_elem = (
        "def __init__(self, scene: rtcs.EmbreeScene, vertices: np.ndarray, indices: np.ndarray):"
    )
    replacement_elem = "def __init__(self, scene: rtcs.EmbreeScene, vertices: npt.NDArray, indices: npt.NDArray) -> None:"
    content = content.replace(target_elem, replacement_elem)

    return content


def post_process_rtcore_scene(content: str) -> str:
    """Apply post-processing to rtcore_scene.pyi."""
    # Normalize line endings
    content = content.replace("\r\n", "\n")

    # Add rich typing imports
    content = content.replace(
        "from typing import TypeAlias as _TypeAlias",
        "from typing import TypeAlias as _TypeAlias, Dict, Literal, Union, overload\nimport numpy.typing as npt",
    )

    # Add typed device field to EmbreeScene class
    content = content.replace(
        "class EmbreeScene:\n    is_committed: int",
        "class EmbreeScene:\n    is_committed: int\n    device: rtc.EmbreeDevice",
    )

    # Add return type to __init__
    content = content.replace(
        "def __init__(self, device: rtc.EmbreeDevice=None, robust=True):",
        "def __init__(self, device: rtc.EmbreeDevice | None = None, robust: bool = True) -> None:",
    )

    # Inject rich overloads for run()
    target_run = "    def run(self, vec_origins: np.ndarray, vec_directions: np.ndarray, dists=None, query='INTERSECT', output=None):\n        ..."

    overloaded_run = """    @overload
    def run(
        self,
        vec_origins: npt.NDArray[np.float32],
        vec_directions: npt.NDArray[np.float32],
        dists: float | npt.NDArray[np.float32] | None = None,
        query: Literal["DISTANCE"] = "DISTANCE",
        output: Literal[False, 0, None] = None,
    ) -> npt.NDArray[np.float32]: ...
    @overload
    def run(
        self,
        vec_origins: npt.NDArray[np.float32],
        vec_directions: npt.NDArray[np.float32],
        dists: float | npt.NDArray[np.float32] | None = None,
        query: Literal["INTERSECT", "OCCLUDED"] = "INTERSECT",
        output: Literal[False, 0, None] = None,
    ) -> npt.NDArray[np.int32]: ...
    @overload
    def run(
        self,
        vec_origins: npt.NDArray[np.float32],
        vec_directions: npt.NDArray[np.float32],
        dists: float | npt.NDArray[np.float32] | None = None,
        query: Literal["INTERSECT", "OCCLUDED", "DISTANCE"] = "INTERSECT",
        *,
        output: Literal[True, 1],
    ) -> Dict[str, npt.NDArray]: ...
    @overload
    def run(
        self,
        vec_origins: npt.NDArray[np.float32],
        vec_directions: npt.NDArray[np.float32],
        dists: float | npt.NDArray[np.float32] | None = None,
        query: str = "INTERSECT",
        output: bool | int | None = None,
    ) -> Union[npt.NDArray, Dict[str, npt.NDArray]]: ..."""

    content = content.replace(target_run, overloaded_run)
    return content


def generate_stubs(output_dir: str | None = None, verbose: bool = False) -> None:
    """
    Generate and post-process type stubs for the embreex package.
    """
    stubgen_bin = get_stubgen_bin()

    cmd = [stubgen_bin, EMBREEX_DIR]

    if output_dir:
        cmd.extend(["--output-dir", output_dir])

    if verbose:
        cmd.append("--verbose")

    cmd.append("--exclude-attribution")

    if verbose:
        print(f"Running command: {' '.join(cmd)}")

    subprocess.run(cmd, capture_output=True, text=True, check=True)

    # Perform post-processing
    target_dir = output_dir if output_dir else EMBREEX_DIR

    # 1. rtcore.pyi
    rtcore_path = os.path.join(target_dir, "rtcore.pyi")
    if os.path.exists(rtcore_path):
        with open(rtcore_path, "r", encoding="utf-8") as f:
            content = f.read()
        processed = post_process_rtcore(content)
        with open(rtcore_path, "w", encoding="utf-8") as f:
            f.write(processed)

    # 2. mesh_construction.pyi
    mesh_path = os.path.join(target_dir, "mesh_construction.pyi")
    if os.path.exists(mesh_path):
        with open(mesh_path, "r", encoding="utf-8") as f:
            content = f.read()
        processed = post_process_mesh_construction(content)
        with open(mesh_path, "w", encoding="utf-8") as f:
            f.write(processed)

    # 3. rtcore_scene.pyi
    scene_path = os.path.join(target_dir, "rtcore_scene.pyi")
    if os.path.exists(scene_path):
        with open(scene_path, "r", encoding="utf-8") as f:
            content = f.read()
        processed = post_process_rtcore_scene(content)
        with open(scene_path, "w", encoding="utf-8") as f:
            f.write(processed)


if __name__ == "__main__":
    print("Generating type stubs for embreex...")
    try:
        generate_stubs(verbose=True)
        print("Success! Type stubs successfully updated.")
    except subprocess.CalledProcessError as e:
        print(f"Error running stubgen-pyx: {e}", file=sys.stderr)
        if e.stderr:
            print(e.stderr, file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)
