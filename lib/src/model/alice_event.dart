import 'package:flutter/widgets.dart';

/// Builds an optional extra section for the event details screen. Return
/// `null` to hide the section for the given [event].
typedef AliceEventDetailBuilder = Widget? Function(
  BuildContext context,
  AliceEvent event,
);

/// Generic event shown in the Alice "Analytics" tab, e.g. a tracked analytics
/// event, a screen change or an app lifecycle change.
@immutable
class AliceEvent {
  AliceEvent({
    required this.name,
    this.category = defaultCategory,
    this.parameters = const {},
    this.metadata = const {},
    this.module,
    this.source,
    DateTime? timestamp,
  })  : id = _nextId++,
        timestamp = timestamp ?? DateTime.now();

  static const String defaultCategory = 'event';

  static int _nextId = 0;

  /// Unique, monotonically increasing identifier.
  final int id;

  /// Time when the event was captured.
  final DateTime timestamp;

  /// Name of the event.
  final String name;

  /// Free-form category used for filtering, e.g. `event`, `screen`.
  final String category;

  /// Parameters sent with the event.
  final Map<String, dynamic> parameters;

  /// Additional context that is not part of the event payload.
  final Map<String, dynamic> metadata;

  /// Module (e.g. package or feature) that reported the event, used for
  /// filtering.
  final String? module;

  /// Where the event was reported from, e.g. a class and a `file:line`.
  final String? source;

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'timestamp': timestamp.toIso8601String(),
        'parameters': parameters,
        if (metadata.isNotEmpty) 'metadata': metadata,
        if (module != null) 'module': module,
        if (source != null) 'source': source,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is AliceEvent && other.id == id;
}
