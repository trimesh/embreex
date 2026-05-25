"""
Test that the committed type stub (.pyi) files are completely up-to-date
with their corresponding Cython (.pyx) source files.
"""

import glob
import os

import pytest

from package.generate_stubs import EMBREEX_DIR, generate_stubs


def test_stubs_are_synchronized(tmp_path):
    """
    Generate type stubs in a temporary directory and verify that they match
    the ones currently committed in the embreex/ directory.
    """
    # 1. Run the generator outputting to the temporary directory
    generate_stubs(output_dir=str(tmp_path))

    # 2. Find all generated .pyi files in the temp directory
    temp_pyi_files = glob.glob(os.path.join(str(tmp_path), "*.pyi"))

    assert temp_pyi_files, (
        "No type stub (.pyi) files were generated. Check Cython source files in embreex/."
    )

    # 3. Compare each generated file with the corresponding file in embreex/
    for temp_path in temp_pyi_files:
        basename = os.path.basename(temp_path)
        repo_path = os.path.join(EMBREEX_DIR, basename)

        # Check that the stub file exists in the repository
        assert os.path.exists(repo_path), (
            f"New type stub file '{basename}' was generated but is not present in the repository.\n"
            f"Please run 'python package/generate_stubs.py' to generate and commit it."
        )

        # Read contents
        with open(temp_path, "r", encoding="utf-8") as f:
            temp_content = f.read()

        with open(repo_path, "r", encoding="utf-8") as f:
            repo_content = f.read()

        # Compare content (ignoring platform-specific line endings)
        temp_normalized = temp_content.replace("\r\n", "\n").strip()
        repo_normalized = repo_content.replace("\r\n", "\n").strip()

        assert temp_normalized == repo_normalized, (
            f"Type stub file '{basename}' is out of sync with the corresponding Cython source file.\n"
            f"Please run 'python package/generate_stubs.py' to synchronize the stub files, and commit the changes."
        )
