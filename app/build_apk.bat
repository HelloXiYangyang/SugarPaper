@echo off
REM Copyright (C) 2026 HelloXiYangyang
REM SPDX-License-Identifier: AGPL-3.0-or-later
REM 糖纸 · SugarPaper —— 一键构建 release APK（带版本号输出）
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_apk.ps1" %*
