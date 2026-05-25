# `debug_attach_pid` — attach to a running process (MCP)

## Summary

Adds MCP tool **`debug_attach_pid`** so agents can attach x32dbg to an already-running process **without** `x32dbg.exe -p` or GUI Attach.

**Root cause fixed:** x64dbg parses command-line numbers as **hex by default**. `attach 3580` attaches to PID `0x3580`, not decimal 3580. This plugin uses **`attach .%u`** (decimal PID per [Values](https://help.x64dbg.com/en/latest/introduction/Values.html)).

**Implementation:** Queue plugin command `mcpattach .PID` → run on x64dbg command thread → `DbgCmdExecDirect("attach .PID")` → wait for `DbgIsDebugging()`.

There is **no** `attachbreak` command in x64dbg; `attach_break` only optionally waits for pause after attach (often times out while game keeps `running` — attach still succeeds).

## MCP tool

| Tool | Args |
|------|------|
| `debug_attach_pid` | `pid` (decimal), `timeout_ms`, `attach_break`, `detach_first` |

## Build (no vcpkg required)

```powershell
powershell -File build-x86.ps1
# -> dist\x32dbg_mcp.dp32
```

Uses **FetchContent** for `nlohmann_json` when vcpkg is absent.

## Verified (Windows, x32dbg 32-bit)

- Empty debugger + `debug_attach_pid` → `main_nocd.exe` / `cmd.exe`, `module_get_main` OK
- Log: `AttachProcessCore: attach .<pid> (decimal pid)`

## Not recommended

- `script_execute` with `attach <pid>` — returns success before attach completes; misleading
- `attach <pid>` without `.` prefix — wrong PID on hex-default parser

## Upstream PR notes

- Tested for automation (Cursor MCP); PonPon game workflow uses LEProc + inject + `debug_attach_pid`
- GUI Attach and `-p` remain valid fallbacks
- Maintainer merge may prefer squashing `mcpattach` into internal attach path only (no extra plugin commands)
