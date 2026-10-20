import 'package:alice/src/helper/alice_event_helper.dart';
import 'package:alice/src/model/alice_event.dart';
import 'package:alice/src/utils/alice_constants.dart';
import 'package:flutter/material.dart';

const _maxVisibleParameterKeys = 6;

class AliceEventListItemWidget extends StatelessWidget {
  const AliceEventListItemWidget(this.event, this.onTap, {super.key});

  final AliceEvent event;
  final ValueChanged<AliceEvent> onTap;

  @override
  Widget build(BuildContext context) {
    final screen = event.metadata['screen'];
    final parameterKeys = event.parameters.keys.toList();
    final hiddenKeysCount = parameterKeys.length - _maxVisibleParameterKeys;
    return InkWell(
      onTap: () => onTap(event),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            AliceEventHelper.formatTime(event.timestamp),
                            if (screen != null) '$screen',
                            if (event.module case final module?) module,
                          ].join(' · '),
                          style: TextStyle(
                            fontSize: 12,
                            color: AliceConstants.grey,
                          ),
                        ),
                        if (parameterKeys.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              for (final key in parameterKeys.take(
                                _maxVisibleParameterKeys,
                              ))
                                _ParameterKeyChip(key),
                              if (hiddenKeysCount > 0)
                                _ParameterKeyChip('+$hiddenKeysCount'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 4, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AliceEventCategoryBadge(event.category),
                      Expanded(
                        child: Center(
                          child: Icon(
                            Icons.chevron_right,
                            color: AliceConstants.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class AliceEventCategoryBadge extends StatelessWidget {
  const AliceEventCategoryBadge(this.category, {super.key});

  final String category;

  @override
  Widget build(BuildContext context) {
    final color = AliceEventHelper.categoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _ParameterKeyChip extends StatelessWidget {
  const _ParameterKeyChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AliceConstants.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
      ),
    );
  }
}
