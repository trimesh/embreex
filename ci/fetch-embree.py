#!/usr/bin/env python3
"""A Python 3 standard library only utility to download embree releases
and copy them into the home directory for every plaform and architecture.
"""

import os
import sys
import json
import tarfile
import logging
import argparse
from io import BytesIO
from fnmatch import fnmatch
from platform import system, machine
from typing import Optional
from zipfile import ZipFile

log = logging.getLogger("embreex")
log.setLevel(logging.DEBUG)
log.addHandler(logging.StreamHandler(sys.stdout))
_cwd = os.path.abspath(os.path.expanduser(os.path.dirname(__file__)))


def fetch(url, sha256):
    """A simple standard-library only "fetch remote URL" function.

    Parameters
    ----------
    url : str
      Location of remote resource.
    sha256: str
      The SHA256 hash of the resource once retrieved,
      will raise a `ValueError` if the hash doesn't match.

    Returns
    -------
    data : bytes
      Retrieved data in memory with correct hash.
    """
    import hashlib
    from urllib.request import urlopen

    data = urlopen(url).read()
    hashed = hashlib.sha256(data).hexdigest()
    if hashed != sha256:
        log.error(f"`{hashed}` != `{sha256}`")
        raise ValueError("sha256 hash does not match!")

    return data


def extract(tar, member, path, chmod):
    """Extract a single member from a tarfile or ZipFile to a path."""
    if os.path.isdir(path):
        return

    if hasattr(tar, "extractfile"):
        # a tarfile
        data = tar.extractfile(member=member)
        if not hasattr(data, "read"):
            return
        data = data.read()
    else:
        # ZipFile
        data = tar.read(member.filename)

    if len(data) == 0:
        return

    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)

    if chmod is not None:
        # python os.chmod takes an octal value
        os.chmod(path, int(str(chmod), base=8))


def handle_fetch(
    url: str,
    sha256: str,
    target: str,
    chmod: Optional[int] = None,
    extract_skip: Optional[list] = None,
    extract_only: Optional[str] = None,
    strip_components: int = 0,
):
    """A macro to fetch a remote resource (archive or single file)
    and move it somewhere on the file system.

    Parameters
    ----------
    url : str
      A string with a remote resource.
    sha256 : str
      A hex string for the hash of the remote resource.
    target : str
      Target location on the local file system.
    chmod : None or int
      Change permissions for extracted files (octal).
    extract_skip : list[str]
      Skip a certain set of patterns from the archive.
    extract_only : str
      Extract only a single file from the archive,
      overrides `extract_skip`.
    strip_components : int
      Number of path components to strip from extracted paths.
    """
    if ".." in target:
        target = os.path.join(_cwd, target)
    target = os.path.abspath(os.path.expanduser(target))

    if os.path.exists(target):
        log.debug(f"`{target}` exists, skipping")
        return

    # get the raw bytes
    log.debug(f"fetching: `{url}`")
    raw = fetch(url=url, sha256=sha256)
    if len(raw) == 0:
        raise ValueError(f"{url} is empty!")

    # handle archive vs single file
    if url.endswith((".tar.gz", ".tar.xz", ".tar.bz2", ".zip")):
        if url.endswith(".zip"):
            tar = ZipFile(BytesIO(raw))
            members = tar.infolist()
        else:
            # deduce tar mode from extension
            ext = url.split(".")[-1]
            mode = f"r:{ext}"  # e.g. "r:gz", "r:xz", ...
            tar = tarfile.open(fileobj=BytesIO(raw), mode=mode)
            members = tar.getmembers()

        if extract_skip is None:
            extract_skip = []

        for member in members:
            # tarfile uses member.name, ZipFile uses member.filename
            name = getattr(member, "filename", getattr(member, "name", ""))
            # apply strip_components
            split_path = name.split("/")
            name_stripped = "/".join(split_path[strip_components:])

            # skip if pattern matches any in extract_skip
            if not extract_only and any(fnmatch(name_stripped, p) for p in extract_skip):
                log.debug(f"skipping: `{name_stripped}`")
                continue

            # if we are extracting only a single file, ignore everything else
            if extract_only:
                # final base name
                base_only = os.path.basename(name_stripped)
                if base_only == extract_only:
                    path = os.path.join(target, base_only)
                    log.debug(f"extracting only `{path}`")
                    extract(tar=tar, member=member, path=path, chmod=chmod)
                    return
            else:
                path = os.path.join(target, name_stripped)
                log.debug(f"extracting: `{path}`")
                extract(tar=tar, member=member, path=path, chmod=chmod)
    else:
        # a single file
        path = target
        with open(path, "wb") as f:
            f.write(raw)
        if chmod is not None:
            os.chmod(path, int(str(chmod), base=8))


def load_config(path: Optional[str] = None) -> list:
    """Load a config file for embree download locations."""
    if path is None or len(path) == 0:
        # use a default config file
        path = os.path.join(_cwd, "embree.json")
    with open(path, "r") as f:
        return json.load(f)


def is_current_platform(platform_name: str) -> bool:
    """
    Check whether the given 'platform_name' from the JSON
    matches our current OS:
      - 'linux'
      - 'darwin' or 'mac'
      - 'windows'
    """
    current = system().lower().strip()
    if current.startswith("dar"):
        return platform_name.startswith("dar") or platform_name.startswith("mac")
    elif current.startswith("win"):
        return platform_name.startswith("win")
    elif current.startswith("lin"):
        return platform_name.startswith("lin")
    else:
        raise ValueError(f"Unrecognized platform: {current}")


def unify_arch_name(raw_arch: str) -> str:
    """
    Normalize architecture names to a smaller set:
      - x86_64
      - arm64
      - amd64  (only if you truly want to treat it differently from x86_64)
    Modify this map if you want to unify 'amd64' and 'x86_64' or treat them separately.
    """
    normalized = raw_arch.lower()
    # Example: unify synonyms if desired
    synonyms = {
        "amd64": "amd64",
        "x86_64": "x86_64",
        "aarch64": "arm64",
        "arm64": "arm64",
    }
    return synonyms.get(normalized, normalized)


def is_current_arch(arch: Optional[str]) -> bool:
    """
    Returns True if the given 'arch' matches our current machine architecture.
    If 'arch' is None or empty, assume it's a match (no arch restriction).
    """
    if not arch:
        return True
    current_arch = unify_arch_name(machine())
    desired_arch = unify_arch_name(arch)
    return current_arch == desired_arch


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Install system packages for trimesh.")
    parser.add_argument("--install", type=str, action="append", help="Install package.")
    parser.add_argument("--config", type=str, help="Specify a different config JSON path")

    args = parser.parse_args()
    config = load_config(path=args.config)

    # --install can appear multiple times; allow comma-delimited as well
    if args.install is None:
        parser.print_help()
        sys.exit(0)
    else:
        select = set(" ".join(args.install).replace(",", " ").split())

    for option in config:
        # Only install if name + OS + arch match
        # Some JSON entries may not have "arch", so default to True if missing
        if (
            option["name"] in select
            and is_current_platform(option["platform"])
            and is_current_arch(option.get("arch"))
        ):
            subset = option.copy()
            # Remove keys not used by 'handle_fetch'
            subset.pop("name", None)
            subset.pop("platform", None)
            subset.pop("arch", None)
            handle_fetch(**subset)
