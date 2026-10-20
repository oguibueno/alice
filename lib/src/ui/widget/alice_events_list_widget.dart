import 'package:alice/src/core/alice_core.dart';
import 'package:alice/src/model/alice_event.dart';
import 'package:alice/src/model/alice_event_filter.dart';
import 'package:alice/src/model/alice_event_sort_option.dart';
import 'package:alice/src/ui/page/alice_event_details_screen.dart';
import 'package:alice/src/ui/widget/alice_event_list_item_widget.dart';
import 'package:alice/src/utils/alice_constants.dart';
import 'package:flutter/material.dart';

class AliceEventsListWidget extends StatelessWidget {
  const AliceEventsListWidget({
    required this.aliceCore,
    required this.query,
    required this.filter,
    required this.onFilterChanged,
    super.key,
  });

  final AliceCore aliceCore;
  final String query;
  final AliceEventFilter filter;
  final ValueChanged<AliceEventFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AliceEvent>>(
      stream: aliceCore.eventsSubject,
      initialData: aliceCore.eventsSubject.value,
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return const _AliceEventsEmptyWidget(
            message: 'There are no events to show',
            hint: '• Check if your app reports events to Alice',
          );
        }
        final visibleEvents = filter.apply(
          events,
          hiddenEventNames: aliceCore.hiddenEventNames,
          query: query,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!filter.isDefault)
              _AliceActiveFiltersBar(
                filter: filter,
                onFilterChanged: onFilterChanged,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(
                'Showing ${visibleEvents.length} of ${events.length} events',
                style: TextStyle(fontSize: 12, color: AliceConstants.grey),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: visibleEvents.isEmpty
                  ? _AliceEventsEmptyWidget(
                      message: 'No events match the filters',
                      action: filter.isDefault
                          ? null
                          : TextButton(
                              key: const Key('events_clear_filters'),
                              onPressed: () =>
                                  onFilterChanged(const AliceEventFilter()),
                              child: const Text('Clear filters'),
                            ),
                    )
                  : ListView.builder(
                      itemCount: visibleEvents.length,
                      itemBuilder: (context, index) => AliceEventListItemWidget(
                        visibleEvents[index],
                        (event) => _onEventTap(context, event),
                        key: ValueKey(visibleEvents[index].id),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _onEventTap(BuildContext context, AliceEvent event) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AliceEventDetailsScreen(event: event, aliceCore: aliceCore),
      ),
    );
  }
}

class _AliceActiveFiltersBar extends StatelessWidget {
  const _AliceActiveFiltersBar({
    required this.filter,
    required this.onFilterChanged,
  });

  final AliceEventFilter filter;
  final ValueChanged<AliceEventFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('events_active_filters'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          if (!filter.isSortDefault)
            _chip(
              'Sorted by ${filter.sortOption.name} '
              '${filter.sortAscending ? '↑' : '↓'}',
              () => onFilterChanged(
                filter.copyWith(
                  sortOption: AliceEventSortOption.time,
                  sortAscending: false,
                ),
              ),
            ),
          for (final category in filter.categories.toList()..sort())
            _chip(
              'Category: $category',
              () => onFilterChanged(
                filter.copyWith(
                  categories: {...filter.categories}..remove(category),
                ),
              ),
            ),
          for (final module in filter.modules.toList()..sort())
            _chip(
              'Module: $module',
              () => onFilterChanged(
                filter.copyWith(modules: {...filter.modules}..remove(module)),
              ),
            ),
          for (final name in filter.includedHiddenNames.toList()..sort())
            _chip(
              'Including $name',
              () => onFilterChanged(
                filter.copyWith(
                  includedHiddenNames: {...filter.includedHiddenNames}
                    ..remove(name),
                ),
              ),
            ),
          TextButton(
            key: const Key('events_clear_all_filters'),
            onPressed: () => onFilterChanged(const AliceEventFilter()),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onDeleted) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: InputChip(
          key: ValueKey('events_active_filter_$label'),
          label: Text(label),
          visualDensity: VisualDensity.compact,
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: onDeleted,
        ),
      );
}

class _AliceEventsEmptyWidget extends StatelessWidget {
  const _AliceEventsEmptyWidget({
    required this.message,
    this.hint,
    this.action,
  });

  final String message;
  final String? hint;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AliceConstants.orange),
            const SizedBox(height: 6),
            Text(message, style: const TextStyle(fontSize: 18)),
            if (hint case final hint?) ...[
              const SizedBox(height: 12),
              Text(hint, style: const TextStyle(fontSize: 12)),
            ],
            if (action case final action?) ...[
              const SizedBox(height: 12),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
