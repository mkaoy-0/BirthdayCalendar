// theme_service.dart

import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart'; // 本物の調和機能を使うために、ここにインポートを追加します！

class ThemeService {
  static const _seedColor = Colors.blue;

  /// Androidのシステム壁紙から抽出された色を元に、アプリに最適なライトモード用のカラースキームを生成
  static ColorScheme createLightScheme(ColorScheme? dynamicColorScheme) {
    if (dynamicColorScheme != null) {
      // harmonized() を使って、壁紙色とアプリ色を完璧に融合させます
      return dynamicColorScheme.harmonized(); 
    }
    return ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
  }
}

