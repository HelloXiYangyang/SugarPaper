/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data' show BytesBuilder;

/// 白噪音场景清单（v5.0 专注场景）。
const kSoundScenes = [
  ('none', '静音', 'close'),
  ('rain', '雨声', 'cloud'),
  ('ocean', '海浪', 'wave'),
  ('forest', '森林', 'leaf'),
  ('cafe', '咖啡馆', 'cup'),
  ('fire', '篝火', 'flame'),
  ('pink', '粉红噪音', 'sparkles'),
  ('brown', '棕噪音', 'moon'),
  ('library', '图书馆', 'book'),
  ('night', '夜虫', 'star'),
];

/// 生成专注白噪音 WAV 文件（16-bit PCM，44.1kHz，30 秒，循环播放）。
Future<File> generateSoundFile(String scene, Directory dir) async {
  const sampleRate = 44100;
  const seconds = 30;
  const n = sampleRate * seconds;
  final samples = List<double>.filled(n, 0);
  final rng = math.Random(20260807);

  switch (scene) {
    case 'rain':
      _rain(samples, rng);
      break;
    case 'ocean':
      _ocean(samples, rng);
      break;
    case 'forest':
      _forest(samples, rng);
      break;
    case 'cafe':
      _cafe(samples, rng);
      break;
    case 'fire':
      _fire(samples, rng);
      break;
    case 'pink':
      _pink(samples, rng);
      break;
    case 'brown':
      _brown(samples, rng);
      break;
    case 'library':
      _library(samples, rng);
      break;
    case 'night':
      _night(samples, rng);
      break;
    default:
      for (var i = 0; i < n; i++) {
        samples[i] = (rng.nextDouble() * 2 - 1) * 0.08;
      }
  }

  final bytes = BytesBuilder();
  void writeLE(int v, int count) {
    for (var i = 0; i < count; i++) {
      bytes.addByte(v & 0xFF);
      v >>= 8;
    }
  }

  final dataSize = n * 2;
  bytes.add('RIFF'.codeUnits);
  writeLE(36 + dataSize, 4);
  bytes.add('WAVE'.codeUnits);
  bytes.add('fmt '.codeUnits);
  writeLE(16, 4); // fmt chunk size
  writeLE(1, 2); // PCM
  writeLE(1, 2); // mono
  writeLE(sampleRate, 4);
  writeLE(sampleRate * 2, 4); // byte rate
  writeLE(2, 2); // block align
  writeLE(16, 2); // bits
  bytes.add('data'.codeUnits);
  writeLE(dataSize, 4);
  for (final s in samples) {
    final v = (s.clamp(-1.0, 1.0) * 32767).round();
    writeLE(v & 0xFFFF, 2);
  }

  final file = File('${dir.path}${Platform.pathSeparator}noise_$scene.wav');
  await file.writeAsBytes(bytes.toBytes());
  return file;
}

/// 一阶低通滤波。
void _lowpass(List<double> src, List<double> dst, double alpha) {
  var y = 0.0;
  for (var i = 0; i < src.length; i++) {
    y += alpha * (src[i] - y);
    dst[i] = y;
  }
}

void _rain(List<double> s, math.Random rng) {
  final raw = List<double>.filled(s.length, 0);
  for (var i = 0; i < s.length; i++) {
    raw[i] = rng.nextDouble() * 2 - 1;
  }
  _lowpass(raw, s, 0.16);
  // 雨势起伏
  for (var i = 0; i < s.length; i++) {
    final t = i / 44100.0;
    final env = 0.65 +
        0.35 *
            math.sin(t * 0.4) *
            math.sin(t * 0.13 + 1.7);
    s[i] *= env * 0.55;
  }
}

void _ocean(List<double> s, math.Random rng) {
  final raw = List<double>.filled(s.length, 0);
  for (var i = 0; i < s.length; i++) {
    raw[i] = rng.nextDouble() * 2 - 1;
  }
  _lowpass(raw, s, 0.05);
  // 海浪周期 8 秒
  for (var i = 0; i < s.length; i++) {
    final t = i / 44100.0;
    final env = 0.45 +
        0.55 *
            math.pow(math.sin(t * 2 * math.pi / 8 + 1.2), 3)
                .toDouble();
    s[i] *= env.clamp(0.0, 1.0) * 0.7;
  }
}

void _forest(List<double> s, math.Random rng) {
  _pink(s, rng);
  // 轻微沙沙：高频分量
  final rustle = List<double>.filled(s.length, 0);
  for (var i = 0; i < s.length; i++) {
    rustle[i] = rng.nextDouble() * 2 - 1;
  }
  _lowpass(rustle, rustle, 0.4);
  for (var i = 0; i < s.length; i++) {
    final t = i / 44100.0;
    s[i] = s[i] * 0.8 + rustle[i] * (0.2 + 0.1 * math.sin(t * 0.6));
    s[i] *= 0.5;
  }
}

void _cafe(List<double> s, math.Random rng) {
  final raw = List<double>.filled(s.length, 0);
  for (var i = 0; i < s.length; i++) {
    raw[i] = rng.nextDouble() * 2 - 1;
  }
  _lowpass(raw, s, 0.07);
  // 人声般的缓慢起伏 + 偶尔杯碟声
  for (var i = 0; i < s.length; i++) {
    final t = i / 44100.0;
    final murmur = 0.75 +
        0.25 *
            math.sin(t * 0.9) *
            math.sin(t * 0.27 + 2.0);
    s[i] *= murmur * 0.5;
  }
  for (var i = 0; i < s.length; i += 44100 * 9) {
    final start = i + rng.nextInt(2000);
    for (var j = start; j < math.min(s.length, start + 1200); j++) {
      final fade = (j - start) / 1200.0;
      s[j] += (rng.nextDouble() * 2 - 1) * 0.12 * (1 - fade);
    }
  }
}

void _fire(List<double> s, math.Random rng) {
  final raw = List<double>.filled(s.length, 0);
  for (var i = 0; i < s.length; i++) {
    raw[i] = rng.nextDouble() * 2 - 1;
  }
  _lowpass(raw, s, 0.12);
  for (var i = 0; i < s.length; i++) {
    s[i] *= 0.22; // 基底火焰声
  }
  // 噼啪爆裂声
  var i = 0;
  while (i < s.length - 800) {
    i += 400 + rng.nextInt(3000);
    if (i >= s.length - 800) break;
    final len = 300 + rng.nextInt(500);
    final f0 = 800.0 + rng.nextDouble() * 2400;
    for (var j = 0; j < len && i + j < s.length; j++) {
      final decay = math.exp(-j / (len * 0.35));
      final phase = 2 * math.pi * f0 * j / 44100.0;
      s[i + j] += math.sin(phase) * 0.4 * decay * (0.5 + 0.5 * rng.nextDouble());
    }
  }
}

void _pink(List<double> s, math.Random rng) {
  var b0 = 0.0, b1 = 0.0, b2 = 0.0, b3 = 0.0, b4 = 0.0, b5 = 0.0, b6 = 0.0;
  for (var i = 0; i < s.length; i++) {
    final white = rng.nextDouble() * 2 - 1;
    b0 = 0.99886 * b0 + white * 0.0555179;
    b1 = 0.99332 * b1 + white * 0.0750759;
    b2 = 0.96900 * b2 + white * 0.1538520;
    b3 = 0.86650 * b3 + white * 0.3104856;
    b4 = 0.55000 * b4 + white * 0.5329522;
    b5 = -0.7616 * b5 - white * 0.0168980;
    final out = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362;
    b6 = white * 0.115926;
    s[i] = out * 0.16;
  }
}

void _brown(List<double> s, math.Random rng) {
  // 棕噪音：白噪声积分（一阶），低频更重
  var last = 0.0;
  for (var i = 0; i < s.length; i++) {
    final white = rng.nextDouble() * 2 - 1;
    last = (last + 0.02 * white) / 1.02;
    s[i] = last * 3.5;
  }
  // 归一化
  var peak = 0.0;
  for (final v in s) {
    if (v.abs() > peak) peak = v.abs();
  }
  if (peak > 0) {
    final gain = 0.5 / peak;
    for (var i = 0; i < s.length; i++) {
      s[i] *= gain;
    }
  }
}

void _library(List<double> s, math.Random rng) {
  for (var i = 0; i < s.length; i++) {
    s[i] = (rng.nextDouble() * 2 - 1) * 0.02;
  }
  // 偶尔翻书声
  var i = 0;
  while (i < s.length - 600) {
    i += 12000 + rng.nextInt(18000);
    if (i >= s.length - 600) break;
    for (var j = 0; j < 600 && i + j < s.length; j++) {
      s[i + j] += (rng.nextDouble() * 2 - 1) * 0.18 * (1 - j / 600.0);
    }
  }
}

void _night(List<double> s, math.Random rng) {
  for (var i = 0; i < s.length; i++) {
    s[i] = (rng.nextDouble() * 2 - 1) * 0.04;
  }
  // 虫鸣 chirp：频率扫描短音
  var i = 0;
  while (i < s.length - 2000) {
    i += 900 + rng.nextInt(1600);
    if (i >= s.length - 2000) break;
    final chirps = 3 + rng.nextInt(4);
    for (var c = 0; c < chirps; c++) {
      final start = i + c * 240;
      for (var j = 0; j < 180 && start + j < s.length; j++) {
        final t = j / 180.0;
        final f = 3800 - t * 1800;
        final env = math.sin(math.pi * t);
        s[start + j] += math.sin(2 * math.pi * f * j / 44100.0) * 0.16 * env;
      }
    }
  }
}
