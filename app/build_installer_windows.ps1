# Copyright (C) 2026 HelloXiYangyang
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# 糖纸 · SugarPaper —— Windows 安装包（Inno Setup）构建脚本
# 用法：powershell -ExecutionPolicy Bypass -File build_installer_windows.ps1 [-Arm64]
# 前置：已安装 Inno Setup 6（https://jrsoftware.org/isinfo.php）
#
# 产物：
#   build/windows/dist/v<版本号>/SugarPaper-v<版本号>-windows-<架构>.exe
#
# 注意：release（AOT）构建要求源码路径不含中文等非 ASCII 字符。

param(
    [switch]$Arm64
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$verLine = Select-String -Path 'pubspec.yaml' -Pattern '^version:' | Select-Object -First 1
if (-not $verLine) {
    Write-Error '无法从 pubspec.yaml 读取版本号'
}
$verMain = (($verLine.Line -replace '^version:\s*', '').Trim() -replace '\s+', '').Split('+')[0]
$arch = if ($Arm64) { 'arm64' } else { 'x64' }

# 定位 ISCC.exe（Inno Setup 6）
$iscc = $null
foreach ($cand in @(
    'E:\Inno\ISCC.exe',
    'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
    'C:\Program Files\Inno Setup 6\ISCC.exe'
)) {
    if (Test-Path $cand) { $iscc = $cand; break }
}
if (-not $iscc) {
    $cmd = Get-Command iscc -ErrorAction SilentlyContinue
    if ($cmd) { $iscc = $cmd.Source }
}
if (-not $iscc) {
    Write-Error '未找到 Inno Setup 6（ISCC.exe）。请先安装：https://jrsoftware.org/isinfo.php'
}

Write-Host "==> 构建糖纸 Windows 安装包 v$verMain（release · $arch）" -ForegroundColor Cyan
if ($Arm64) {
    flutter build windows --release --target-platform windows-arm64
} else {
    flutter build windows --release
}

Write-Host "==> 运行 Inno Setup 打包..." -ForegroundColor Cyan
& $iscc "/DMyAppVersion=$verMain" "/DMyArch=$arch" 'packaging\windows\sugarpaper.iss'
if ($LASTEXITCODE -ne 0) {
    Write-Error "Inno Setup 打包失败（exit $LASTEXITCODE）"
}

$setup = Join-Path (Get-Location) "build\windows\dist\v$verMain\SugarPaper-v$verMain-windows-$arch.exe"
if (-not (Test-Path $setup)) {
    Write-Error "安装包未生成：$setup"
}
$size = [math]::Round((Get-Item $setup).Length / 1MB, 1)
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $setup).Hash.ToLower()
Write-Host "==> 安装包完成：$setup（${size} MB）" -ForegroundColor Green
Write-Host "    SHA-256: $hash" -ForegroundColor Green
