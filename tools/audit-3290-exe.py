"""Read-only audit of CrashGuards signatures in the game's PE .text section.

This does not load, execute, hook, patch or install anything. A unique
signature match is necessary but NOT sufficient to prove a patch is safe:
control flow, relocation, instructions and game behavior still need review.
"""
import argparse
import hashlib
from pathlib import Path
import re
import struct

def pe_text(path):
    data = path.read_bytes()
    if data[:2] != b'MZ':
        raise ValueError("Not a PE file")
    pe = struct.unpack_from("<I", data, 0x3c)[0]
    if data[pe:pe+4] != b"PE\x00\x00":
        raise ValueError("Invalid PE signature")
    sections = struct.unpack_from("<H", data, pe+6)[0]
    optsize = struct.unpack_from("<H", data, pe+20)[0]
    st = pe+24+optsize
    for i in range(sections):
        at = st + i*40
        name = data[at:at+8].rstrip(b'\0')
        if name == b'.text':
            rawsize, rawptr = struct.unpack_from("<II", data, at+16)
            if rawptr+rawsize > len(data):
                raise ValueError("Invalid .text extent")
            return data[rawptr:rawptr+rawsize], rawptr
    raise ValueError("No .text section")

def signatures(source):
    text = source.read_text(encoding="utf-8")
    # Game-code patches and the auxiliary pattern-derived AI/knowledge offsets.
    patterns = list(re.findall(r'\{\s*"([^"]+)",\s*"([0-9A-Fa-f? ]{25,})"\s*,', text))
    patterns += [("offset " + name, sig) for name, sig in
                 re.findall(r'constexpr const char\* (c_[A-Za-z0-9_]+) = "([0-9A-Fa-f? ]{25,})";', text)]
    for name, pattern in patterns:
        tokens = pattern.split()
        expression = b"".join(b'.' if v == "??" else re.escape(bytes.fromhex(v)) for v in tokens)
        yield name, re.compile(expression, re.DOTALL)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("exe", type=Path, help="Path to HITMAN3.exe (read-only)")
    args = ap.parse_args()
    base = Path(__file__).resolve().parent.parent
    text, raw_offset = pe_text(args.exe)
    print("HITMAN PE SHA256:", hashlib.sha256(args.exe.read_bytes()).hexdigest())
    print("Code section bytes:", len(text))
    bad = 0
    patterns = dict(signatures(base / "plugin/Src/CrashGuards.cpp"))
    tension = list(patterns["offset c_SetTension"].finditer(text))
    for name, rx in patterns.items():
        if name == "offset c_RuntimeId" and len(tension) == 1:
            # CrashGuards::Install restricts this pattern to 0x180 bytes after
            # the *unique* SetTension match, not the entire executable.
            at = tension[0].start()
            matches = list(rx.finditer(text, at, at + 0x180))
        else:
            matches = list(rx.finditer(text))
        found = [m.start()+raw_offset for m in matches]
        state = "unique" if len(found) == 1 else f"{len(found)} matches"
        print(f"{name}: {state}", ("file offset 0x%x" % found[0] if len(found)==1 else ""))
        bad += (len(found)!=1)
    print("UNVERIFIED: even unique signatures do NOT certify native hooks safe.")
    if bad:
        print("WARNING:", bad, "patch signature(s) do not match uniquely.")
    return 0 if bad == 0 else 2

if __name__ == "__main__":
    raise SystemExit(main())
