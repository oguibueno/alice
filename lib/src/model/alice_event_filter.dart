import 'package:alice/src/helper/alice_event_helper.dart';
import 'package:alice/src/model/alice_event.dart';
import 'package:alice/src/model/alice_event_sort_option.dart';
import 'package:flutter/foundation.dart';

/// Filters and sorting applied to the events of the "Analytics" tab.
@immutable
class AliceEventFilter {
  const AliceEventFilter({
    this.categories = const {},
    this.modules = const {},
    this.includedHiddenNames = const {},
    this.sortOption = AliceEventSortOption.time,
    this.sortAscending = false,
  });

  /// Categories to show, or all when empty.
  final Set<String> categories;

  /// Modules to show, or all when empty.
  final Set<String> modules;

  /// Hidden event names that are shown anyway.
  final Set<String> includedHiddenNames;

  final AliceEventSortOption sortOption;
  final bool sortAscending;

  bool get isSortDefault =>
      sortOption == AliceEventSortOption.time && !sortAscending;

  bool get isDefault =>
      categories.isEmpty &&
      modules.isEmpty &&
      includedHiddenNames.isEmpty &&
      isSortDefault;

  int get activeFilterCount =>
      categories.length +
      modules.length +
      includedHiddenNames.length +
      (isSortDefault ? 0 : 1);

  AliceEventFilter copyWith({
    Set<String>? categories,
    Set<String>? modules,
    Set<String>? includedHiddenNames,
    AliceEventSortOption? sortOption,
    bool? sortAscending,
  }) =>
      AliceEventFilter(
        categories: categories ?? this.categories,
        modules: modules ?? this.modules,
        includedHiddenNames: includedHiddenNames ?? this.includedHiddenNames,
        sortOption: sortOption ?? this.sortOption,
        sortAscending: sortAscending ?? this.sortAscending,
      );

  /// Returns the [events] that match this filter and [query], sorted.
  List<AliceEvent> apply(
    List<AliceEvent> events, {
    required Set<String> hiddenEventNames,
    String query = '',
  }) {
    final matching = events
        .where(
          (event) =>
              (!hiddenEventNames.contains(event.name) ||
                  includedHiddenNames.contains(event.name)) &&
              (categories.isEmpty || categories.contains(event.category)) &&
              (modules.isEmpty || modules.contains(event.module)) &&
              AliceEventHelper.matches(event, query),
        )
        .toList();

    int compare(AliceEvent a, AliceEvent b) {
      switch (sortOption) {
        case AliceEventSortOption.time:
          return a.id.compareTo(b.id);
        case AliceEventSortOption.name:
          final byName = a.name.compareTo(b.name);
          return byName != 0 ? byName : a.id.compareTo(b.id);
      }
    }

    return matching
      ..sort((a, b) => sortAscending ? compare(a, b) : compare(b, a));
  }

  @override
  bool operator ==(Object other) =>
      other is AliceEventFilter &&
      setEquals(other.categories, categories) &&
      setEquals(other.modules, modules) &&
      setEquals(other.includedHiddenNames, includedHiddenNames) &&
      other.sortOption == sortOption &&
      other.sortAscending == sortAscending;

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(categories),
        Object.hashAllUnordered(modules),
        Object.hashAllUnordered(includedHiddenNames),
        sortOption,
        sortAscending,
      );
}
