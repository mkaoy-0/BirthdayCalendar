// theme_service.dart

import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';

class ThemeService {
  static const _seedColor = Color.fromARGB(255, 89, 161, 220);

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

  /// Androidのシステム壁紙から抽出された色を元に、ダークモード用のカラースキームを生成
  static ColorScheme createDarkScheme(ColorScheme? dynamicColorScheme) {
    if (dynamicColorScheme != null) {
      return dynamicColorScheme.harmonized().copyWith(
        brightness: Brightness.dark,
      );
    }
    return ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
  }
}

