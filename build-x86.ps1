# Setsuna MCP x86 build (pip cmake + VS2022 BuildTools)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$cmake = 'C:\Users\93202\AppData\Roaming\Python\Python314\Scripts\cmake.exe'
if (-not (Test-Path $cmake)) { throw "cmake not found: $cmake" }

$vcvars = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars32.bat"
if (-not (Test-Path $vcvars)) { throw "vcvars32 not found: $vcvars" }

cmd /c "`"$vcvars`" && set" | ForEach-Object {
    if ($_ -match '^(.*?)=(.*)$') { Set-Item -Path "env:$($matches[1])" -Value $matches[2] }
}

Set-Location $root
if (-not (Test-Path dist)) { New-Item -ItemType Directory -Path dist | Out-Null }

Write-Host '=== CMake configure x86 ==='
& $cmake -B build_x86 -G 'Visual Studio 17 2022' -A Win32 -DCMAKE_BUILD_TYPE=Release -DXDBG_ARCH=x86
if ($LASTEXITCODE -ne 0) { throw 'configure failed' }

Write-Host '=== CMake build x86 ==='
& $cmake --build build_x86 --config Release -j
if ($LASTEXITCODE -ne 0) { throw 'build failed' }

$out = Join-Path $root 'build_x86\bin\Release\x32dbg_mcp.dp32'
if (-not (Test-Path $out)) { throw "output missing: $out" }
Copy-Item $out (Join-Path $root 'dist\x32dbg_mcp.dp32') -Force
Write-Host "[OK] dist\x32dbg_mcp.dp32"
