import 'package:flutter/material.dart';
import 'package:voo_logging/src/domain/value_objects/log_level_color.dart';

/// Adapter to convert domain colors to Flutter colors
class ColorAdapter {
  static Color toFlutterColor(LogLevelColor color) {
    return Color.fromRGBO(
      color.red,
      color.green,
      color.blue,
      color.opacity,
    );
  }
}