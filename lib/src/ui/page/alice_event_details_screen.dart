import 'package:alice/src/core/alice_core.dart';
import 'package:alice/src/helper/alice_event_helper.dart';
import 'package:alice/src/model/alice_event.dart';
import 'package:alice/src/ui/widget/alice_event_list_item_widget.dart';
import 'package:alice/src/utils/alice_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class AliceEventDetailsScreen extends StatelessWidget {
  const AliceEventDetailsScreen({
    required this.event,
    required this.aliceCore,
    super.key,
  });

  final AliceEvent event;
  final AliceCore aliceCore;

  @override
  Widget build(BuildContext context) {
    final extraSection = aliceCore.eventDetailBuilder?.call(context, event);
    final tabs = [
      const Tab(icon: Icon(Icons.info_outline), text: 'Overview'),
      const Tab(icon: Icon(Icons.list), text: 'Parameters'),
      const Tab(icon: Icon(Icons.data_object), text: 'Raw'),
      if (extraSection != null)
        const Tab(icon: Icon(Icons.menu_book_outlined), text: 'Details'),
    ];
    return Directionality(
      textDirection: aliceCore.directionality ?? Directionality.of(context),
      child: DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Alice - Event Details'),
            actions: [
              IconButton(
                key: const Key('copy_event_name'),
                tooltip: 'Copy name',
                icon: const Icon(Icons.copy),
                onPressed: () => _copy(context, event.name),
              ),
              IconButton(
                key: const Key('copy_event_json'),
                tooltip: 'Copy JSON',
                icon: const Icon(Icons.data_object),
                onPressed: () => _copy(context, _json),
              ),
            ],
            bottom: TabBar(
              indicatorColor: AliceConstants.lightRed,
              tabAlignment: TabAlignment.fill,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              tabs: tabs,
            ),
          ),
          floatingActionButton: aliceCore.showShareButton ?? false
              ? FloatingActionButton(
                  key: const Key('share_key'),
                  backgroundColor: AliceConstants.lightRed,
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(text: _json, subject: event.name),
                  ),
                  child: Icon(Icons.share, color: AliceConstants.white),
                )
              : null,
          body: TabBarView(
            children: [
              _AliceEventOverviewWidget(event),
              _AliceEventParametersWidget(event),
              _AliceEventRawWidget(_json),
              if (extraSection != null) extraSection,
            ],
          ),
        ),
      ),
    );
  }

  String get _json => AliceEventHelper.toPrettyJson(event.toJson());
}

Future<void> _copy(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied!')));
  }
}

class _AliceEventOverviewWidget extends StatelessWidget {
  const _AliceEventOverviewWidget(this.event);

  final AliceEvent event;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SelectableText(
          event.name,
          style: const TextStyle(fontSize: 20, fontFamily: 'monospace'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AliceEventCategoryBadge(event.category),
        ),
        const SizedBox(height: 16),
        _AliceKeyValueRow('Time', event.timestamp.toString()),
        _AliceKeyValueRow('Parameters', '${event.parameters.length}'),
        if (event.module case final module?)
          _AliceKeyValueRow('Module', module),
        if (event.source case final source?)
          _AliceKeyValueRow('Logged from', source),
        for (final entry in event.metadata.entries)
          _AliceKeyValueRow(
            entry.key,
            AliceEventHelper.formatValue(entry.value),
          ),
      ],
    );
  }
}

class _AliceEventParametersWidget extends StatelessWidget {
  const _AliceEventParametersWidget(this.event);

  final AliceEvent event;

  @override
  Widget build(BuildContext context) {
    if (event.parameters.isEmpty) {
      return const Center(child: Text('This event has no parameters'));
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final entry in event.parameters.entries)
          _AliceKeyValueRow(
            entry.key,
            AliceEventHelper.formatValue(entry.value),
            copyable: true,
          ),
      ],
    );
  }
}

class _AliceEventRawWidget extends StatelessWidget {
  const _AliceEventRawWidget(this.json);

  final String json;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SelectableText(
        json,
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }
}

class _AliceKeyValueRow extends StatelessWidget {
  const _AliceKeyValueRow(this.name, this.value, {this.copyable = false});

  final String name;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: copyable ? () => _copy(context, '$name: $value') : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 2),
            if (copyable) Text(value) else SelectableText(value),
          ],
        ),
      ),
    );
  }
}
