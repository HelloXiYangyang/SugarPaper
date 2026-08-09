# Copyright (C) 2026 HelloXiYangyang
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# 糖纸 · SugarPaper —— Windows 桌面版一键构建脚本
# 用法：powershell -ExecutionPolicy Bypass -File build_windows.ps1 [-Debug] [-Arm64]
#
# 产物（软件包命名规范见 README）：
#   build/windows/dist/v<版本号>/SugarPaper-v<版本号>-windows-<架构>.zip   （绿色版）
#
# 注意：release（AOT）构建要求源码路径不含中文等非 ASCII 字符，
# 请通过纯英文路径（如 D:\SugarPaperDev 目录联接）运行本脚本。

param(
    [switch]$Debug,
    [switch]$Arm64
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

# 从 pubspec.yaml 读取版本号（格式：version: 0.31.0+50）
$verLine = Select-String -Path 'pubspec.yaml' -Pattern '^version:' | Select-Object -First 1
if (-not $verLine) {
    Write-Error '无法从 pubspec.yaml 读取版本号'
}
$ver = ($verLine.Line -replace '^version:\s*', '').Trim() -replace '\s+', ''
$verMain = $ver.Split('+')[0]

$mode = if ($Debug) { 'debug' } else { 'release' }
$arch = if ($Arm64) { 'arm64' } else { 'x64' }
$cfgName = if ($Debug) { 'Debug' } else { 'Release' }
$srcDir = Join-Path (Get-Location) "build\windows\$arch\runner\$cfgName"
$distDir = Join-Path (Get-Location) "build\windows\dist\v$verMain"
New-Item -ItemType Directory -Force -Path $distDir | Out-Null

Write-Host "==> 构建糖纸 Windows 桌面版 v$verMain（$mode · $arch）" -ForegroundColor Cyan
if ($Debug) {
    if ($Arm64) {
        flutter build windows --debug --target-platform windows-arm64
    } else {
        flutter build windows --debug
    }
} else {
    if ($Arm64) {
        flutter build windows --release --target-platform windows-arm64
    } else {
        flutter build windows --release
    }
}

$zipName = if ($Debug) {
    "SugarPaper-v$verMain-windows-$arch-debug.zip"
} else {
    "SugarPaper-v$verMain-windows-$arch.zip"
}
$zipDest = Join-Path $distDir $zipName
if (Test-Path $zipDest) { Remove-Item -LiteralPath $zipDest -Force }
Compress-Archive -Path "$srcDir\*" -DestinationPath $zipDest -CompressionLevel Optimal
$size = [math]::Round((Get-Item $zipDest).Length / 1MB, 1)
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipDest).Hash.ToLower()
Write-Host "==> 绿色版完成：$zipDest（${size} MB）" -ForegroundColor Green
Write-Host "    SHA-256: $hash" -ForegroundColor Green
