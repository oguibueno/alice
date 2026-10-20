import 'dart:convert';

import 'package:alice/src/model/alice_event.dart';
import 'package:alice/src/utils/alice_constants.dart';
import 'package:flutter/material.dart';

class AliceEventHelper {
  AliceEventHelper._();

  static const _encoder = JsonEncoder.withIndent('  ', _toEncodable);

  static final _categoryColors = [
    AliceConstants.green,
    AliceConstants.orange,
    Colors.blue,
    Colors.purple,
    Colors.teal,
    AliceConstants.grey,
  ];

  /// Formats [time] as `HH:mm:ss.SSS`.
  static String formatTime(DateTime time) {
    String pad(int value, [int width = 2]) =>
        value.toString().padLeft(width, '0');
    return '${pad(time.hour)}:${pad(time.minute)}:${pad(time.second)}'
        '.${pad(time.millisecond, 3)}';
  }

  static String toPrettyJson(Object? value) => _encoder.convert(value);

  static String formatValue(Object? value) =>
      value is String ? value : toPrettyJson(value);

  static Color categoryColor(String category) {
    final index = category.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return _categoryColors[index % _categoryColors.length];
  }

  /// Whether [event] matches the free-text [query] by name, category,
  /// parameter keys or parameter values.
  static bool matches(AliceEvent event, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }
    bool contains(Object? value) =>
        '$value'.toLowerCase().contains(normalizedQuery);
    return contains(event.name) ||
        contains(event.category) ||
        (event.module != null && contains(event.module)) ||
        event.parameters.entries.any(
          (entry) => contains(entry.key) || contains(entry.value),
        );
  }

  static Object? _toEncodable(Object? value) {
    if (value is DateTime) {
      return value.toIso8601String();
    }
    return value.toString();
  }
}
