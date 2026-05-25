embreeX
========

A fork of [scopatz/pyembree](https://github.com/scopatz/pyembree) that is configured to
build wheels for Intel Mac, Windows, and Linux for Python 3.6 and newer. The name change
is to avoid confusion with the other forks and install methods available. 

The goal is to meet the upstream `trimesh[easy]` preferences for dependencies,
which are: "`easy` requirements should install without compiling anything on
Windows/Linux/Intel Mac for Python 3.6+ and have minimal dependencies."



## Install

The main goal of this fork is to provide wheels for the original project:
```
# will install an embree binding with only numpy as a dependency
pip install embreex
```

## Development

If you are contributing to this project or modifying Cython bindings, you can auto-generate type stubs and run static validation without needing to compile the extension library or install standard C++ compilation tooling.

### Generating Type Stubs

When you modify Cython files (`.pyx` or `.pxd`), auto-generate and synchronize the `.pyi` type stubs by running:
```bash
python package/generate_stubs.py
```

### Running Tests and Type Validation

Verify that your type stubs are completely up to date and that static type checking passes:

```bash
# 1. Run the stub synchronization test
PYTHONPATH=. pytest tests/test_stubs.py

# 2. Run static type analysis
mypy
```

## Alternatives

The original project is [available on conda-forge](https://anaconda.org/conda-forge/pyembree/files) for many versons of Python. For wheel-based options currently on PyPi there are:
- https://pypi.org/project/pyembree/
  - https://github.com/adam-grant-hendry/pyembree
  - Currently set up with cibuildwheel as of writing with released wheels for Mac/Windows/Linux on Python 3.8
- https://pypi.org/project/embree/
  - A re-write to simplify the binding.
  - Wheels building.
