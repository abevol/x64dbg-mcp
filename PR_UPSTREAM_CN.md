## 概述

新增 MCP 工具 **`debug_attach_pid`**：在 x32dbg/x64dbg **已打开、未附加** 时，由自动化（Cursor 等）附加到**已在运行**的进程，无需 `x32dbg.exe -p` 或 GUI「附加」。

同时修复一个容易踩坑的问题：x64dbg 命令行里**数字默认按十六进制解析**。`attach 3580` 实际附加的是 PID `0x3580`，不是十进制 3580。本 PR 统一使用 **`attach .%u`**（`.` 表示十进制，见[官方 Values 文档](https://help.x64dbg.com/en/latest/introduction/Values.html)）。

## 背景问题

- 用 `script_execute` 执行 `attach <pid>` 时，经常**命令还没真正附加完就返回 success**；此时 `debug_get_state: stopped` 也可能只是**未在调试**。
- 直接 `attach <十进制PID>` 在默认解析下会附到错误进程。
- x64dbg **没有** `attachbreak` 这条命令（已移除相关错误用法）。

## 实现要点

- 新 MCP 工具：`debug_attach_pid`（参数：`pid`、`timeout_ms`、`attach_break`、`detach_first`）。
- 在 **x64dbg 命令线程** 执行插件命令：`mcpattach .PID` / `mcpattachbreak .PID` / `mcpdetach`。
- `DebugController::AttachProcessCore` → `DbgCmdExecDirect("attach .%u")`，并等待 `DbgIsDebugging()` 为真。
- 可选：无 vcpkg 时用 CMake **FetchContent** 拉 `nlohmann_json`（`build-x86.ps1` 辅助 x86 构建）。

## 实测环境

- Windows 10，x32dbg 32 位，插件版本 `1.0.8-attach`。
- 空载调试器 → `debug_attach_pid` → `module_get_main`、`breakpoint_set` 正常。
- 日志可见：`AttachProcessCore: attach .<pid> (decimal pid)`。

## 已知限制

- `attach_break: true` 时，目标若一直 **running**，`WaitForPause` 可能超时，但**附加本身通常已成功**；自动化场景建议 `attach_break: false`。
- 失败时的错误码/文案尚未完全打磨。
- 未在本 PR 中单独修复旧版 `script_execute attach` 的“假成功”语义（可另开 issue）。

## 文档

详见本 PR 中的 **`ATTACH.md`**（英文技术说明，含构建与 API 表）。

## 主要改动文件

- `src/business/DebugController.cpp` / `.h`
- `src/handlers/DebugHandler.cpp` / `.h`
- `src/core/MCPToolRegistry.cpp`
- `src/PluginEntry.cpp`
- `ATTACH.md`
- `CMakeLists.txt`、`build-x86.ps1`（可选无 vcpkg 构建路径）
