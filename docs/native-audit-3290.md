# Native compatibility audit: HITMAN 3.290.1.0

Read-only signature audit against the actual installed HITMAN3.exe:
- SHA256: 0E0DC96305BF26C2D9B1D3E65C31F549987A779901FA2750D2F93CB0D4A441EF
- Executable file version: 3.290.1.0
- SDK runtime currently installed: 4.1.1.0 (not compatible with our experimental 4.2.0-compiled DLL)
- Official SDK v4.2.0 binary is only in the isolated workspace, not installed

| CrashGuards pattern | Matches in executable .text |
|---|---|
| restart guard 1 | unique |
| restart guard 2 | unique |
| restart guard 3 | unique |
| speech | unique |
| reasoning | unique |
| perceptibility guard | unique |
| c_UnitsCaller | unique |
| c_UnitsIndex | unique |
| c_SetTension | unique |
| c_RuntimeId (within 0x180 bytes after c_SetTension, as runtime searches) | unique |

The audit tests pattern *existence and uniqueness only*. It DOES NOT exercise
the injected machine-code trampoline, its dynamic call targets, ABI/prologue,
Patch/Uninstall races, ZActor fields, pause hooks, or PoseHook's old Morpheme
interface assumptions. All of those need runtime gameplay verification.

## Further defensive fixes

1. SpawnPartner now **waits** for a valid, locally resolvable outfit kit,
   valid charset and nonnegative variation rather than spawning an NPC with
   an unresolvable outfit (a plausible cause of an invisible stand-in).
2. PoseHook now checks the memory protection and bounds of the native output
   pose before copying or overwriting its bones. It only hooks an executable
   vtable function in the HITMAN3.exe image, not an arbitrary trampoline.
3. PoseHook::Uninstall avoids overwriting another later-installed vtable hook.
4. RigScan rejects null and implausible animator/skeleton/depth inputs before
   following pointers through undocumented engine structures.

These changes are defensive; they have not proven the partner appears in a
real 3.290.1.0 co-op mission. An actual two-PC test is still required.

Reproduce: `py -3 tools/audit-3290-exe.py "C:\Program Files (x86)\Steam\steamapps\common\HITMAN 3\Retail\HITMAN3.exe"`
