# Pull Request 正文（复制到 GitHub PR 描述框）

## Summary

Adds MCP tool **`debug_attach_pid`** to attach x32dbg/x64dbg to an **already running** process from automation (Cursor / MCP clients), without `x32dbg.exe -p` or GUI Attach.

Fixes a subtle but critical bug: x64dbg command-line numbers are **hex by default**. `attach 3580` attaches to PID `0x3580`, not decimal 3580. This change uses **`attach .%u`** (decimal PID per [Values](https://help.x64dbg.com/en/latest/introduction/Values.html)).

## Problem

- `script_execute` with `attach <pid>` often returns **success before attach completes**; `debug_get_state: stopped` can mean **not debugging**.
- Plain `attach <decimal_pid>` targets the wrong process on hex-default parsing.
- There is **no** `attachbreak` command in x64dbg.

## Solution

- New MCP tool: `debug_attach_pid` (`pid`, `timeout_ms`, `attach_break`, `detach_first`).
- Plugin commands on the **command thread**: `mcpattach .PID`, `mcpattachbreak .PID`, `mcpdetach`.
- `DebugController::AttachProcessCore` → `DbgCmdExecDirect("attach .%u")` + wait for `DbgIsDebugging()`.
- Optional: CMake **FetchContent** for `nlohmann_json` when vcpkg is absent (`build-x86.ps1`).

## Tested

- Windows 10, x32dbg 32-bit, plugin `1.0.8-attach`.
- Empty debugger → `debug_attach_pid` → `module_get_main` / `breakpoint_set` OK.
- Log line: `AttachProcessCore: attach .<pid> (decimal pid)`.

## Known limitations

- `attach_break: true` may **timeout** waiting for pause while the target keeps running; attach still succeeds in practice.
- Error codes / failure messages not fully polished.
- Does not fix misleading success of legacy `script_execute attach` (separate issue).

## Docs

See **`ATTACH.md`** in this PR.

## Files (main)

- `src/business/DebugController.cpp`, `DebugController.h`
- `src/handlers/DebugHandler.cpp`, `DebugHandler.h`
- `src/core/MCPToolRegistry.cpp`
- `src/PluginEntry.cpp`
- `ATTACH.md`
- `CMakeLists.txt`, `build-x86.ps1` (optional build path)
