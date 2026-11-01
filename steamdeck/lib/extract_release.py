#!/usr/bin/env python3
"""Safely extract a Windows Artur Edition ZIP, including Windows backslash entries."""
import pathlib
import stat
import sys
import zipfile

def main():
    if len(sys.argv) != 3:
        raise ValueError("usage: extract_release.py ARCHIVE DESTINATION")
    dest = pathlib.Path(sys.argv[2]).resolve()
    dest.mkdir(parents=True, exist_ok=True)
    total = 0
    with zipfile.ZipFile(sys.argv[1]) as archive:
        for entry in archive.infolist():
            name = entry.filename.replace("\\", "/")
            parts = pathlib.PurePosixPath(name).parts
            if (name.startswith("/") or not parts or
                    any(p in ("..", "") for p in parts) or ":" in parts[0]):
                raise ValueError(f"unsafe archive path: {name!r}")
            if stat.S_ISLNK((entry.external_attr >> 16) & 0xFFFF):
                raise ValueError(f"archive contains symlink: {name!r}")
            total += entry.file_size
            if total > 350 * 1024 * 1024 or entry.file_size > 150 * 1024 * 1024:
                raise ValueError("archive exceeds safe extraction size limit")
            target = dest.joinpath(*parts)
            if not target.resolve().is_relative_to(dest):
                raise ValueError(f"archive path escapes destination: {name!r}")
            if entry.is_dir() or name.endswith("/"):
                target.mkdir(parents=True, exist_ok=True)
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            with archive.open(entry) as src, target.open("wb") as out:
                import shutil
                shutil.copyfileobj(src, out)
    print("Extracted validated ZIP to", dest)
if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, zipfile.BadZipFile) as exc:
        print(f"Unsafe or invalid release ZIP: {exc}", file=sys.stderr)
        sys.exit(1)
