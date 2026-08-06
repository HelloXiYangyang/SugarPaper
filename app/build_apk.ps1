# Copyright (C) 2026 HelloXiYangyang
# SPDX-License-Identifier: AGPL-3.0-or-later

# 糖纸 · SugarPaper —— 安卓版一键构建脚本
# 用法：powershell -ExecutionPolicy Bypass -File build_apk.ps1 [-Debug] [-SplitAbi]
#
# 软件包命名规范（统一格式）：
#   SugarPaper-v<版本号>-<平台>[-<ABI>].<扩展名>
#   例如：
#     SugarPaper-v0.17.0-android.apk              （通用包，含全部 ABI）
#     SugarPaper-v0.17.0-android-arm64-v8a.apk     （分 ABI 包）
#     SugarPaper-v0.17.0-android-x86_64.apk

param(
    [switch]$Debug,
    [switch]$SplitAbi
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

# 从 pubspec.yaml 读取版本号（格式：version: 0.17.0+42）
$verLine = Select-String -Path 'pubspec.yaml' -Pattern '^version:' | Select-Object -First 1
if (-not $verLine) {
    Write-Error '无法从 pubspec.yaml 读取版本号'
}
$ver = ($verLine.Line -replace '^version:\s*', '').Trim()
$ver = $ver -replace '\s+', ''
$verMain = $ver.Split('+')[0]

$outDir = 'build\app\outputs\flutter-apk'
$versionDir = Join-Path $outDir "v$verMain"
New-Item -ItemType Directory -Force -Path $versionDir | Out-Null

if ($Debug) {
    Write-Host "==> 构建糖纸安卓版 v$ver（debug）" -ForegroundColor Cyan
    flutter build apk --debug
    $src = Join-Path $outDir 'app-debug.apk'
    $name = "SugarPaper-v$verMain-android-debug.apk"
    $dest = Join-Path $versionDir $name
    Copy-Item -Force $src $dest
    $size = [math]::Round((Get-Item $dest).Length / 1MB, 1)
    Write-Host "==> 构建完成：$dest（${size} MB）" -ForegroundColor Green
    exit 0
}

if ($SplitAbi) {
    Write-Host "==> 构建糖纸安卓版 v$ver（release · 分 ABI）" -ForegroundColor Cyan
    flutter build apk --release --split-per-abi
    $abis = @('arm64-v8a', 'armeabi-v7a', 'x86_64')
    foreach ($abi in $abis) {
        $src = Join-Path $outDir "app-$abi-release.apk"
        if (Test-Path $src) {
        $dest = Join-Path $versionDir "SugarPaper-v$verMain-android-$abi.apk"
            Copy-Item -Force $src $dest
            $size = [math]::Round((Get-Item $dest).Length / 1MB, 1)
            Write-Host "==> 构建完成：$dest（${size} MB）" -ForegroundColor Green
        }
    }
    exit 0
}

Write-Host "==> 构建糖纸安卓版 v$ver（release · 通用包）" -ForegroundColor Cyan
flutter build apk --release
$src = Join-Path $outDir 'app-release.apk'
$dest = Join-Path $versionDir "SugarPaper-v$verMain-android.apk"
Copy-Item -Force $src $dest
$size = [math]::Round((Get-Item $dest).Length / 1MB, 1)
Write-Host "==> 构建完成：$dest（${size} MB）" -ForegroundColor Green
