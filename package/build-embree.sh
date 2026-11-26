#!/bin/bash
# Build Embree and oneTBB from source into `./embree4` for platforms
# where Embree has no binary release, which is currently Linux aarch64.
# Versions match what the Embree binary releases in `embree.json` contain.
set -euo pipefail

EMBREE_VERSION="4.4.0"
EMBREE_SHA256="acb517b0ea0f4b442235d5331b69f96192c28da6aca5d5dde0cbe40799638d5c"
TBB_VERSION="2021.12.0"
TBB_SHA256="c7bb7aa69c254d91b8f0041a71c5bcc3936acb64408a1719aec0b2b7639dd84f"

# install next to `setup.py` which is where it looks for embree
PREFIX="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/embree4"
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT
cd "$BUILD"

fetch() {
    # fetch a tarball, check the hash and extract it to a directory
    curl -fsSL --retry 3 -o "$3.tar.gz" "$1"
    echo "$2  $3.tar.gz" | sha256sum -c -
    mkdir "$3"
    tar -xzf "$3.tar.gz" -C "$3" --strip-components=1
}

fetch "https://github.com/uxlfoundation/oneTBB/archive/refs/tags/v${TBB_VERSION}.tar.gz" \
      "$TBB_SHA256" tbb
fetch "https://github.com/RenderKit/embree/archive/refs/tags/v${EMBREE_VERSION}.tar.gz" \
      "$EMBREE_SHA256" embree

cmake -S tbb -B tbb-build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$PREFIX" \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DTBB_TEST=OFF \
      -DTBB_STRICT=OFF
cmake --build tbb-build --parallel "$(nproc)"
cmake --install tbb-build

# On non-Apple ARM the Embree default is plain NEON, set it explicitly.
cmake -S embree -B embree-build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$PREFIX" \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DEMBREE_MAX_ISA=NEON \
      -DEMBREE_TASKING_SYSTEM=TBB \
      -DEMBREE_TBB_ROOT="$PREFIX" \
      -DEMBREE_TUTORIALS=OFF \
      -DEMBREE_ISPC_SUPPORT=OFF
cmake --build embree-build --parallel "$(nproc)"
cmake --install embree-build
