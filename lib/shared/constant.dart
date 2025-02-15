import 'package:flutter/material.dart';

class AppConstants {
  static const List<String> importanceLevels = [
    'less-important',
    'mildly-important',
    'important',
    'very-important',
  ];

  static const List<Color> importanceColors = [
    Color(0xFF22C55E), // green
    Color(0xFFEAB308), // yellow
    Color(0xFFF97316), // orange
    Color(0xFFEF4444), // red
  ];

  static String toTitleCase(String str) {
    return str
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  static const delimeter = "||||";
}
