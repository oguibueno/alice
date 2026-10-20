import 'package:alice/src/model/alice_event.dart';
import 'package:alice/src/model/alice_event_filter.dart';
import 'package:alice/src/model/alice_event_sort_option.dart';
import 'package:flutter/material.dart';

/// Opens the "Filter & sort" bottom sheet for the "Analytics" tab and returns
/// the applied filter, or `null` when the sheet is dismissed.
Future<AliceEventFilter?> showAliceEventsFilterSheet(
  BuildContext context, {
  required List<AliceEvent> events,
  required Set<String> hiddenEventNames,
  required AliceEventFilter filter,
}) =>
    showModalBottomSheet<AliceEventFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => _AliceEventsFilterSheet(
        events: events,
        hiddenEventNames: hiddenEventNames,
        initialFilter: filter,
      ),
    );

class _AliceEventsFilterSheet extends StatefulWidget {
  const _AliceEventsFilterSheet({
    required this.events,
    required this.hiddenEventNames,
    required this.initialFilter,
  });

  final List<AliceEvent> events;
  final Set<String> hiddenEventNames;
  final AliceEventFilter initialFilter;

  @override
  State<_AliceEventsFilterSheet> createState() =>
      _AliceEventsFilterSheetState();
}

class _AliceEventsFilterSheetState extends State<_AliceEventsFilterSheet> {
  late var _filter = widget.initialFilter;

  late final _categoryCounts = _countBy((event) => event.category);
  late final _moduleCounts = _countBy((event) => event.module);
  late final _hiddenCounts = _countBy(
    (event) => widget.hiddenEventNames.contains(event.name) ? event.name : null,
  );

  Map<String, int> _countBy(String? Function(AliceEvent) keyOf) {
    final counts = <String, int>{};
    for (final event in widget.events) {
      final key = keyOf(event);
      if (key != null) {
        counts.update(key, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    return Map.fromEntries(
      counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  'Filter & sort',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const _AliceSheetHeading('Sort by'),
                SegmentedButton<AliceEventSortOption>(
                  key: const Key('events_filter_sort'),
                  segments: const [
                    ButtonSegment(
                      value: AliceEventSortOption.time,
                      label: Text('Time'),
                    ),
                    ButtonSegment(
                      value: AliceEventSortOption.name,
                      label: Text('Name'),
                    ),
                  ],
                  selected: {_filter.sortOption},
                  onSelectionChanged: (selection) => setState(
                    () => _filter = _filter.copyWith(
                      sortOption: selection.single,
                    ),
                  ),
                ),
                SwitchListTile(
                  key: const Key('events_filter_ascending'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ascending'),
                  value: _filter.sortAscending,
                  onChanged: (value) => setState(
                    () => _filter = _filter.copyWith(sortAscending: value),
                  ),
                ),
                if (_categoryCounts.isNotEmpty) ...[
                  const _AliceSheetHeading('Category'),
                  _buildChips(
                    keyPrefix: 'events_filter_category',
                    counts: _categoryCounts,
                    selectedOf: (filter) => filter.categories,
                    update: (filter, categories) =>
                        filter.copyWith(categories: categories),
                  ),
                ],
                if (_moduleCounts.isNotEmpty) ...[
                  const _AliceSheetHeading('Module'),
                  _buildChips(
                    keyPrefix: 'events_filter_module',
                    counts: _moduleCounts,
                    selectedOf: (filter) => filter.modules,
                    update: (filter, modules) =>
                        filter.copyWith(modules: modules),
                  ),
                ],
                if (_hiddenCounts.isNotEmpty) ...[
                  const _AliceSheetHeading('Hidden events'),
                  for (final MapEntry(key: name, value: count)
                      in _hiddenCounts.entries)
                    SwitchListTile(
                      key: Key('events_filter_include_$name'),
                      contentPadding: EdgeInsets.zero,
                      title: Text('Include $name ($count)'),
                      value: _filter.includedHiddenNames.contains(name),
                      onChanged: (isIncluded) => setState(
                        () => _filter = _filter.copyWith(
                          includedHiddenNames: _toggled(
                            _filter.includedHiddenNames,
                            name,
                            isSelected: isIncluded,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('events_filter_reset'),
                    onPressed: () =>
                        setState(() => _filter = const AliceEventFilter()),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('events_filter_apply'),
                    onPressed: () => Navigator.of(context).pop(_filter),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips({
    required String keyPrefix,
    required Map<String, int> counts,
    required Set<String> Function(AliceEventFilter) selectedOf,
    required AliceEventFilter Function(AliceEventFilter, Set<String>) update,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final MapEntry(key: value, value: count) in counts.entries)
          FilterChip(
            key: Key('${keyPrefix}_$value'),
            label: Text('$value ($count)'),
            selected: selectedOf(_filter).contains(value),
            onSelected: (isSelected) => setState(
              () => _filter = update(
                _filter,
                _toggled(selectedOf(_filter), value, isSelected: isSelected),
              ),
            ),
          ),
      ],
    );
  }

  static Set<String> _toggled(
    Set<String> values,
    String value, {
    required bool isSelected,
  }) =>
      isSelected ? {...values, value} : ({...values}..remove(value));
}

class _AliceSheetHeading extends StatelessWidget {
  const _AliceSheetHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}
