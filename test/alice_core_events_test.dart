// ignore_for_file: cascade_invocations
import 'package:alice/alice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AliceCore createCore({int maxEventsCount = 1000}) => AliceCore(
        darkTheme: false,
        maxCallsCount: 1000,
        maxEventsCount: maxEventsCount,
      );

  group('AliceCore events', () {
    test('appends events in capture order', () {
      final core = createCore();
      final first = AliceEvent(name: 'first');
      final second = AliceEvent(name: 'second');

      core
        ..addEvent(first)
        ..addEvent(second);

      expect(core.eventsSubject.value, [first, second]);
    });

    test('drops the oldest events when the limit is reached', () {
      final core = createCore(maxEventsCount: 2);
      final events = [for (var i = 0; i < 3; i++) AliceEvent(name: 'e$i')];

      events.forEach(core.addEvent);

      expect(core.eventsSubject.value, events.sublist(1));
    });

    test('removes all events', () {
      final core = createCore()..addEvent(AliceEvent(name: 'event'));

      core.removeEvents();

      expect(core.eventsSubject.value, isEmpty);
    });
  });

  group('AliceCore logs', () {
    test('notifies listeners when a log is added', () {
      final core = createCore();
      var notifications = 0;
      core.logger.listenable.addListener(() => notifications++);

      core.addLog(AliceLog(message: 'message'));

      expect(notifications, 1);
      expect(core.logger.logs.single.message, 'message');
    });

    test('notifies listeners when logs are cleared', () {
      final core = createCore()..addLog(AliceLog(message: 'message'));
      var notifications = 0;
      core.logger.listenable.addListener(() => notifications++);

      core.logger.clearLogs();

      expect(notifications, 1);
      expect(core.logger.logs, isEmpty);
    });
  });

  group('AliceEvent', () {
    test('serializes to JSON', () {
      final timestamp = DateTime(2026, 10, 20, 6, 25, 14);
      final event = AliceEvent(
        name: 'trx_block_toggle_tapped',
        category: 'marketing',
        parameters: const {'level': 'global'},
        metadata: const {'screen': '/cardBlocking'},
        module: 'feature_cards',
        source: 'CardBlockingCubit.toggle',
        timestamp: timestamp,
      );

      expect(event.toJson(), {
        'name': 'trx_block_toggle_tapped',
        'category': 'marketing',
        'timestamp': timestamp.toIso8601String(),
        'parameters': {'level': 'global'},
        'metadata': {'screen': '/cardBlocking'},
        'module': 'feature_cards',
        'source': 'CardBlockingCubit.toggle',
      });
    });
  });
}
