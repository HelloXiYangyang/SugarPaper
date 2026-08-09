# Copyright (C) 2026 HelloXiYangyang
# SPDX-License-Identifier: GPL-3.0-or-later

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

# 构建前强制同步：从项目主仓库镜像源码到当前构建目录（排除构建产物/缓存），
# 保证打包的永远是最新代码（增量复制可能漏掉主仓库刚修改的文件）。
$repoAppRoot = 'D:\项目\GitHub项目\SugarPaper\app'
if (Test-Path $repoAppRoot) {
    Write-Host "==> 同步主仓库最新代码到构建目录..." -ForegroundColor Cyan
    robocopy $repoAppRoot $root /MIR /XD "build" ".dart_tool" ".idea" /XF "*.iml" /NFL /NDL /NJH /NP | Out-Null
    Write-Host "==> 同步完成（镜像模式，删除主仓库已移除的文件）" -ForegroundColor Cyan
}

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

# 同步目标：项目原仓库中的同一归档位置（Windows 中文路径工作区）
$syncRoot = 'D:\项目\GitHub项目\SugarPaper'
if (Test-Path $syncRoot) {
    $syncDir = Join-Path $syncRoot "app\build\app\outputs\flutter-apk\v$verMain"
    New-Item -ItemType Directory -Force -Path $syncDir | Out-Null
} else {
    $syncDir = $null
}

function Sync-ToRepo([string]$src) {
    if ($syncDir -and (Test-Path $src)) {
        Copy-Item -Force $src (Join-Path $syncDir (Split-Path -Leaf $src))
        Write-Host "已同步到原仓库：$(Join-Path $syncDir (Split-Path -Leaf $src))" -ForegroundColor DarkCyan
    }
}

if ($Debug) {
    Write-Host "==> 构建糖纸安卓版 v$ver（debug）" -ForegroundColor Cyan
    flutter build apk --debug
    $src = Join-Path $outDir 'app-debug.apk'
    $name = "SugarPaper-v$verMain-android-debug.apk"
    $dest = Join-Path $versionDir $name
    Copy-Item -Force $src $dest
    Sync-ToRepo $dest
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
            Sync-ToRepo $dest
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
Sync-ToRepo $dest
$size = [math]::Round((Get-Item $dest).Length / 1MB, 1)
Write-Host "==> 构建完成：$dest（${size} MB）" -ForegroundColor Green
