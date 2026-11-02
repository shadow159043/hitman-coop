#!/usr/bin/env python3
"""Package a Linux/Steam Deck distribution with reproducible Unix file permissions.

This is a maintainer-side tool only: end users need no Python installation.
"""
import stat
import sys
import zipfile
from pathlib import Path

EXECUTABLES = {"INSTALL-ARTUR-EDITION.desktop", "START-ARTUR-EDITION.sh"}

def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("Usage: package-zip.py STAGING_DIRECTORY OUTPUT.zip")
    source = Path(sys.argv[1]).resolve(strict=True)
    target = Path(sys.argv[2]).resolve()
    if not source.is_dir():
        raise SystemExit(f"Not a staging directory: {source}")
    if target.is_relative_to(source):
        raise SystemExit("Refusing to write the ZIP inside its staging tree")
    files = sorted(p for p in source.rglob("*") if p.is_file())
    if not files:
        raise SystemExit("Refusing to package an empty directory")
    if any(p.is_symlink() for p in source.rglob("*")):
        raise SystemExit("Refusing to include symlinks in release archive")
    required = {"INSTALL-ARTUR-EDITION.desktop", "START-ARTUR-EDITION.sh", "steamdeck/ui-install.sh"}
    present = {p.relative_to(source).as_posix() for p in files}
    if not required <= present:
        raise SystemExit(f"Missing required launcher files: {sorted(required - present)}")

    target.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(target, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9, allowZip64=True) as archive:
        for path in files:
            relative = path.relative_to(source).as_posix()
            is_executable = relative in EXECUTABLES or (relative.startswith("steamdeck/") and relative.endswith(".sh"))
            mode = 0o755 if is_executable else 0o644
            info = zipfile.ZipInfo(relative, date_time=(2026, 11, 2, 12, 0, 0))
            info.create_system = 3  # Unix, even when authored on the Windows release runner
            info.external_attr = (stat.S_IFREG | mode) << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            with path.open("rb") as reader, archive.open(info, "w") as writer:
                while chunk := reader.read(1024 * 1024):
                    writer.write(chunk)
    with zipfile.ZipFile(target) as archive:
        for name in required:
            info = archive.getinfo(name)
            mode = (info.external_attr >> 16) & 0o777
            if info.create_system != 3 or mode & 0o111 != 0o111:
                raise SystemExit(f"Executable permission not preserved for {name}")
        if len(archive.namelist()) != len(set(archive.namelist())):
            raise SystemExit("Duplicate ZIP member detected")
    print(f"Verified executable ZIP entry permissions: {target}")

if __name__ == "__main__":
    main()
