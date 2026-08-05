#!/usr/bin/env python
import os
import sys

from setuptools import setup

from Cython.Build import cythonize
from numpy import get_include

# the current working directory
_cwd = os.path.abspath(os.path.expanduser(os.path.dirname(__file__)))


def ext_modules():
    """Generate a list of extension modules for embreex."""
    # Fetch oneTBB headers separately; Embree's bundle contains only the runtime.
    tbb_include = os.path.join(_cwd, "tbb", "include")
    cxx_std = ["-std=c++11"] if os.name != "nt" else ["/std:c++14"]

    if os.name == "nt":
        # embree search locations on windows
        includes = [
            get_include(),
            "c:/Program Files/Intel/Embree4/include",
            os.path.join(_cwd, "embree4", "include"),
            tbb_include,
        ]
        libraries = [
            "c:/Program Files/Intel/Embree4/lib",
            os.path.join(_cwd, "embree4", "lib"),
        ]
    else:
        # embree search locations on posix
        includes = [
            get_include(),
            "/opt/local/include",
            os.path.join(_cwd, "embree4", "include"),
            tbb_include,
        ]
        libraries = ["/opt/local/lib", os.path.join(_cwd, "embree4", "lib")]

    ext_modules = cythonize("embreex/*.pyx", include_path=includes, language_level=3)
    for ext in ext_modules:
        ext.include_dirs = includes
        ext.library_dirs = libraries
        ext.extra_compile_args = getattr(ext, "extra_compile_args", []) + cxx_std
        # on macOS with Embree 4.x, link against the versioned library directly
        if sys.platform == "darwin":
            # `libtbb.dylib` is a symlink created by `package/embree.json`
            ext.libraries = ["embree4.4", "tbb"]
            # Add rpath to find libembree4 during build and set loader_path for runtime
            ext.extra_link_args = [
                "-Wl,-rpath,@loader_path",
                "-Wl,-rpath," + os.path.join(_cwd, "embree4", "lib"),
            ]
        elif os.name == "nt":
            # the import library in the embree bundle is `tbb12.lib`
            ext.libraries = ["embree4", "tbb12"]
        else:
            ext.libraries = ["embree4", "tbb"]

    return ext_modules


def load_pyproject() -> dict:
    """A hack for Python 3.6 to load data from `pyproject.toml`

    The rest of setup is specified in `pyproject.toml` but moving dependencies
    to `pyproject.toml` requires setuptools>61 which is only available on Python>3.7
    When you drop Python 3.6 you can delete this function.
    """
    # this hack is only needed on Python 3.6 and older
    if sys.version_info >= (3, 7):
        return {}

    import tomli

    with open(os.path.join(_cwd, "pyproject.toml"), "r") as f:
        pyproject = tomli.load(f)

    return {
        "name": pyproject["project"]["name"],
        "version": pyproject["project"]["version"],
        "install_requires": pyproject["project"]["dependencies"],
    }


try:
    with open(os.path.join(_cwd, "README.md"), "r") as _f:
        long_description = _f.read()
except BaseException:
    long_description = ""

setup(
    ext_modules=ext_modules(),
    long_description=long_description,
    long_description_content_type="text/markdown",
    **load_pyproject(),
)
