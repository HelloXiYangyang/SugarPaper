/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';

/// 马卡龙主题 Token（从 Web 版 `theme.css` 移植，v4.13 七套平行主题）。
class SugarThemeData {
  final bool dark;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color text;
  final Color text2;
  final Color text3;
  final Color border;
  final Color border2;
  final Color glass;

  final Color pink;
  final Color pinkStrong;
  final Color pinkSoft;
  final Color mint;
  final Color mintStrong;
  final Color mintSoft;
  final Color sky;
  final Color skyStrong;
  final Color skySoft;
  final Color lavender;
  final Color lavenderStrong;
  final Color lavenderSoft;
  final Color peach;
  final Color peachStrong;
  final Color peachSoft;
  final Color yellow;
  final Color yellowStrong;
  final Color yellowSoft;
  final Color danger;
  final Color dangerStrong;
  final Color dangerSoft;
  final Color success;

  const SugarThemeData({
    required this.dark,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.text,
    required this.text2,
    required this.text3,
    required this.border,
    required this.border2,
    required this.glass,
    required this.pink,
    required this.pinkStrong,
    required this.pinkSoft,
    required this.mint,
    required this.mintStrong,
    required this.mintSoft,
    required this.sky,
    required this.skyStrong,
    required this.skySoft,
    required this.lavender,
    required this.lavenderStrong,
    required this.lavenderSoft,
    required this.peach,
    required this.peachStrong,
    required this.peachSoft,
    required this.yellow,
    required this.yellowStrong,
    required this.yellowSoft,
    required this.danger,
    required this.dangerStrong,
    required this.dangerSoft,
    required this.success,
  });

  /// 从 16 进制色串解析颜色。
  static Color hex(String s) {
    var h = s.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }

  /// 构造完整浅色主题（默认经典白）。
  static SugarThemeData light({
    Color bg = const Color(0xFFFBF6F2),
    Color surface = const Color(0xFFFFFFFF),
    Color surface2 = const Color(0xFFF7EEE9),
    Color surface3 = const Color(0xFFF0E3DD),
    Color pink = const Color(0xFFF4B8CE),
    Color pinkStrong = const Color(0xFFE292B4),
    Color pinkSoft = const Color(0xFFFBE4EC),
    Color mint = const Color(0xFFA9E0CB),
    Color mintStrong = const Color(0xFF5FB894),
    Color mintSoft = const Color(0xFFDEF3EA),
    Color sky = const Color(0xFFB3D4F0),
    Color skyStrong = const Color(0xFF6FA8D6),
    Color skySoft = const Color(0xFFE2EEF9),
    Color lavender = const Color(0xFFC9C7F0),
    Color lavenderStrong = const Color(0xFF8F89D9),
    Color lavenderSoft = const Color(0xFFECEBFA),
    Color peach = const Color(0xFFFAD1B8),
    Color peachStrong = const Color(0xFFE89A6B),
    Color peachSoft = const Color(0xFFFDEBE0),
    Color yellow = const Color(0xFFFBE6B9),
    Color yellowStrong = const Color(0xFFD9A94A),
    Color yellowSoft = const Color(0xFFFDF4DC),
    Color success = const Color(0xFF5FB894),
  }) {
    return SugarThemeData(
      dark: false,
      bg: bg,
      surface: surface,
      surface2: surface2,
      surface3: surface3,
      text: const Color(0xFF463B45),
      text2: const Color(0xFF8C7E88),
      text3: const Color(0xFFB8AAB3),
      border: const Color(0xFFEFE1DA),
      border2: const Color(0xFFE2D1C9),
      glass: const Color(0xD1FFFFFF),
      pink: pink,
      pinkStrong: pinkStrong,
      pinkSoft: pinkSoft,
      mint: mint,
      mintStrong: mintStrong,
      mintSoft: mintSoft,
      sky: sky,
      skyStrong: skyStrong,
      skySoft: skySoft,
      lavender: lavender,
      lavenderStrong: lavenderStrong,
      lavenderSoft: lavenderSoft,
      peach: peach,
      peachStrong: peachStrong,
      peachSoft: peachSoft,
      yellow: yellow,
      yellowStrong: yellowStrong,
      yellowSoft: yellowSoft,
      danger: const Color(0xFFE58B8B),
      dangerStrong: const Color(0xFFD96A6A),
      dangerSoft: const Color(0xFFFBE6E6),
      success: success,
    );
  }

  /// 暗色独立主题。
  static SugarThemeData darkTheme() {
    return const SugarThemeData(
      dark: true,
      bg: Color(0xFF231D2B),
      surface: Color(0xFF2E2738),
      surface2: Color(0xFF372F43),
      surface3: Color(0xFF403750),
      text: Color(0xFFF1EAF0),
      text2: Color(0xFFB7AABF),
      text3: Color(0xFF85778F),
      border: Color(0xFF3D344A),
      border2: Color(0xFF4C4159),
      glass: Color(0xD12E2738),
      pink: Color(0xFFD98FAF),
      pinkStrong: Color(0xFFE6A6C0),
      pinkSoft: Color(0xFF4A3345),
      mint: Color(0xFF7FBFA4),
      mintStrong: Color(0xFF8FD4B4),
      mintSoft: Color(0xFF2E3F3A),
      sky: Color(0xFF7FA8CB),
      skyStrong: Color(0xFF9CC3E2),
      skySoft: Color(0xFF2E3A46),
      lavender: Color(0xFF9E9AD0),
      lavenderStrong: Color(0xFFB6B2E4),
      lavenderSoft: Color(0xFF3A3650),
      peach: Color(0xFFD9A583),
      peachStrong: Color(0xFFEDBFA0),
      peachSoft: Color(0xFF46352C),
      yellow: Color(0xFFD4B268),
      yellowStrong: Color(0xFFE8CB8A),
      yellowSoft: Color(0xFF403A28),
      danger: Color(0xFFD97F7F),
      dangerStrong: Color(0xFFE89A9A),
      dangerSoft: Color(0xFF452F2F),
      success: Color(0xFF8FD4B4),
    );
  }

  /// 七套平行主题（PRD v4.13）。
  static SugarThemeData byKey(String key) {
    switch (key) {
      case 'bluegreen':
        return light(
          bg: hex('#F2FAF7'),
          surface2: hex('#E9F4F0'),
          surface3: hex('#DCECE6'),
          pink: hex('#9ED8C6'),
          pinkStrong: hex('#55B39A'),
          pinkSoft: hex('#DDF2EA'),
          mint: hex('#A8D8E8'),
          mintStrong: hex('#5FA8C9'),
          mintSoft: hex('#E0F1F7'),
          sky: hex('#B0CFF0'),
          skyStrong: hex('#6FA0D6'),
          skySoft: hex('#E3EFF9'),
          lavender: hex('#C3D9E8'),
          lavenderStrong: hex('#7FA6C0'),
          lavenderSoft: hex('#E4EFF6'),
          peach: hex('#F6D9B2'),
          peachStrong: hex('#E2A468'),
          peachSoft: hex('#FCEFE0'),
          yellow: hex('#F2E3A8'),
          yellowStrong: hex('#CBAB4C'),
          yellowSoft: hex('#FAF3DB'),
          success: hex('#55B39A'),
        );
      case 'sunshine':
        return light(
          bg: hex('#FDF8EF'),
          surface2: hex('#F7EFDF'),
          surface3: hex('#EFE3CC'),
          pink: hex('#F8CE9E'),
          pinkStrong: hex('#E8A85F'),
          pinkSoft: hex('#FCEEDD'),
          mint: hex('#DFE3A0'),
          mintStrong: hex('#B0B255'),
          mintSoft: hex('#F4F3DA'),
          sky: hex('#B4D4EF'),
          skyStrong: hex('#6FA0D4'),
          skySoft: hex('#E3EFF9'),
          lavender: hex('#EECBB8'),
          lavenderStrong: hex('#CE8F74'),
          lavenderSoft: hex('#F9E8DF'),
          peach: hex('#F9C9A8'),
          peachStrong: hex('#E2976B'),
          peachSoft: hex('#FCE8DA'),
          yellow: hex('#F7E2A2'),
          yellowStrong: hex('#D1A846'),
          yellowSoft: hex('#FAF2D8'),
          success: hex('#B0B255'),
        );
      case 'rose':
        return light(
          bg: hex('#FDF4F5'),
          surface2: hex('#F9E9EC'),
          surface3: hex('#F2DADE'),
          pink: hex('#F5BCC4'),
          pinkStrong: hex('#E2889B'),
          pinkSoft: hex('#FCE6EA'),
          mint: hex('#B9DED0'),
          mintStrong: hex('#63B294'),
          mintSoft: hex('#E0F2EA'),
          sky: hex('#E8C4D4'),
          skyStrong: hex('#D18AA6'),
          skySoft: hex('#FAE8EF'),
          lavender: hex('#E0C4E8'),
          lavenderStrong: hex('#A978C6'),
          lavenderSoft: hex('#F3E6F8'),
          peach: hex('#F6C8B0'),
          peachStrong: hex('#E08E68'),
          peachSoft: hex('#FCE8DC'),
          yellow: hex('#F6E0AE'),
          yellowStrong: hex('#CFA44E'),
          yellowSoft: hex('#FAF1DA'),
          success: hex('#63B294'),
        );
      case 'lavender':
        return light(
          bg: hex('#F8F5FD'),
          surface2: hex('#F1ECF9'),
          surface3: hex('#E6DCF1'),
          pink: hex('#D5C8F2'),
          pinkStrong: hex('#9F8FE0'),
          pinkSoft: hex('#EFEBFB'),
          mint: hex('#A9E0CB'),
          mintStrong: hex('#5FB894'),
          mintSoft: hex('#DEF3EA'),
          sky: hex('#C4CCF0'),
          skyStrong: hex('#7F8FD4'),
          skySoft: hex('#E9EBFA'),
          lavender: hex('#C9B8EC'),
          lavenderStrong: hex('#8A71C9'),
          lavenderSoft: hex('#F0EAFB'),
          peach: hex('#F2C4D8'),
          peachStrong: hex('#D98FAC'),
          peachSoft: hex('#F9E8EF'),
          yellow: hex('#F4E2A8'),
          yellowStrong: hex('#CDA94E'),
          yellowSoft: hex('#FAF3DB'),
          success: hex('#5FB894'),
        );
      case 'mint':
        return light(
          bg: hex('#F1FAF4'),
          surface2: hex('#E4F3EA'),
          surface3: hex('#D4EADB'),
          pink: hex('#BFE8C9'),
          pinkStrong: hex('#6FC79B'),
          pinkSoft: hex('#E4F5E9'),
          mint: hex('#A9E0CB'),
          mintStrong: hex('#5FB894'),
          mintSoft: hex('#DEF3EA'),
          sky: hex('#B3D4F0'),
          skyStrong: hex('#6FA8D6'),
          skySoft: hex('#E2EEF9'),
          lavender: hex('#C9C7F0'),
          lavenderStrong: hex('#8F89D9'),
          lavenderSoft: hex('#ECEBFA'),
          peach: hex('#F6D9C4'),
          peachStrong: hex('#E3A076'),
          peachSoft: hex('#FCEEE3'),
          yellow: hex('#F2E6B8'),
          yellowStrong: hex('#CBAB54'),
          yellowSoft: hex('#FAF4DF'),
          success: hex('#5FB894'),
        );
      case 'dark':
        return darkTheme();
      case 'classic':
      default:
        return light();
    }
  }

  ThemeData toThemeData() {
    final scheme = ColorScheme.fromSeed(
      seedColor: pinkStrong,
      brightness: dark ? Brightness.dark : Brightness.light,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      splashFactory: NoSplash.splashFactory,
      dividerColor: border,
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: text, fontSize: 14),
        bodySmall: TextStyle(color: text2, fontSize: 12),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: glass,
        elevation: 0,
        foregroundColor: text,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: glass,
        selectedItemColor: pinkStrong,
        unselectedItemColor: text3,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: text,
        contentTextStyle: TextStyle(color: surface, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

/// ThemeExtension：把马卡龙 Token 与动画开关注入主题，组件经
/// `Theme.of(context).extension<SugarTheme>()` 读取。
class SugarTheme extends ThemeExtension<SugarTheme> {
  final SugarThemeData data;
  final bool animations; // 动画总开关
  final String frameRate; // 帧率模式

  const SugarTheme({
    required this.data,
    required this.animations,
    required this.frameRate,
  });

  @override
  SugarTheme copyWith({
    SugarThemeData? data,
    bool? animations,
    String? frameRate,
  }) {
    return SugarTheme(
      data: data ?? this.data,
      animations: animations ?? this.animations,
      frameRate: frameRate ?? this.frameRate,
    );
  }

  @override
  SugarTheme lerp(covariant SugarTheme? other, double t) {
    if (other == null) return this;
    return SugarTheme(
      data: t < 0.5 ? data : other.data,
      animations: t < 0.5 ? animations : other.animations,
      frameRate: t < 0.5 ? frameRate : other.frameRate,
    );
  }
}
