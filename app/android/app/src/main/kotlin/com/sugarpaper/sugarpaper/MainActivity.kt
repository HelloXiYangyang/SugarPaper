/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package com.sugarpaper.sugarpaper

import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "sugarpaper/device"
    private var channel: MethodChannel? = null
    private var pendingDownloadId: Long = -1L
    private var pendingFileName: String = ""

    private val downloadReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action != DownloadManager.ACTION_DOWNLOAD_COMPLETE) return
            val id = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1L)
            if (id != pendingDownloadId) return
            val dm = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
            val q = DownloadManager.Query().setFilterById(id)
            var ok = false
            dm.query(q).use { c ->
                if (c.moveToFirst()) {
                    val status = c.getInt(c.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
                    ok = status == DownloadManager.STATUS_SUCCESSFUL
                }
            }
            channel?.invokeMethod(
                "onDownloadComplete",
                mapOf("success" to ok, "fileName" to pendingFileName)
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                "downloadInBackground" -> {
                    val url = call.argument<String>("url") ?: ""
                    val fileName = call.argument<String>("fileName") ?: "sugarpaper-update.apk"
                    val title = call.argument<String>("title") ?: "糖纸 · SugarPaper 更新"
                    try {
                        val dm = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
                        val request = DownloadManager.Request(Uri.parse(url))
                            .setTitle(title)
                            .setDescription("正在后台下载更新，完成后可安装")
                            .setMimeType("application/vnd.android.package-archive")
                            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                            .setAllowedOverMetered(true)
                            .setDestinationInExternalFilesDir(this, null, fileName)
                        pendingDownloadId = dm.enqueue(request)
                        pendingFileName = fileName
                        result.success(pendingDownloadId)
                    } catch (e: Exception) {
                        result.error("download_failed", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        ContextCompat.registerReceiver(
            this,
            downloadReceiver,
            IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE),
            ContextCompat.RECEIVER_NOT_EXPORTED
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        runCatching { unregisterReceiver(downloadReceiver) }
    }
}
