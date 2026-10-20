import 'package:alice/alice.dart';
import 'package:alice/src/ui/page/alice_calls_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AliceCore createCore({
    AliceEventDetailBuilder? eventDetailBuilder,
    Set<String> hiddenEventNames = const {},
  }) =>
      AliceCore(
        darkTheme: false,
        maxCallsCount: 1000,
        eventDetailBuilder: eventDetailBuilder,
        hiddenEventNames: hiddenEventNames,
        showShareButton: false,
      );

  Future<void> pumpAnalyticsTab(WidgetTester tester, AliceCore core) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: AliceCallsListScreen(core, core.logger)),
    );
    await tester.pump();
    await tester.tap(find.text('ANALYTICS'));
    await tester.pumpAndSettle();
  }

  Future<void> openFilterSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('events_filter_button')));
    await tester.pumpAndSettle();
  }

  Future<void> applyFilterSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('events_filter_apply')));
    await tester.pumpAndSettle();
  }

  testWidgets('shows events added while the tab is open', (tester) async {
    final core = createCore();
    await pumpAnalyticsTab(tester, core);

    expect(find.text('There are no events to show'), findsOneWidget);

    core.addEvent(
      AliceEvent(
        name: 'card_security_viewed',
        parameters: const {'card_type': 'x'},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('card_security_viewed'), findsOneWidget);
    expect(find.text('card_type'), findsOneWidget);
    expect(find.text('Showing 1 of 1 events'), findsOneWidget);
  });

  testWidgets('filters events by category from the sheet', (tester) async {
    final core = createCore()
      ..addEvent(AliceEvent(name: 'signup_started', category: 'marketing'))
      ..addEvent(AliceEvent(name: '/cardBlocking', category: 'screen'));
    await pumpAnalyticsTab(tester, core);

    await openFilterSheet(tester);
    await tester.tap(find.byKey(const Key('events_filter_category_marketing')));
    await applyFilterSheet(tester);

    expect(find.text('signup_started'), findsOneWidget);
    expect(find.text('/cardBlocking'), findsNothing);
    expect(find.text('Showing 1 of 2 events'), findsOneWidget);
    expect(find.text('Category: marketing'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('events_filter_button')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('searches by parameter value', (tester) async {
    final core = createCore()
      ..addEvent(
        AliceEvent(
          name: 'trx_block_toggle_tapped',
          parameters: const {'level': 'a'},
        ),
      )
      ..addEvent(
        AliceEvent(
          name: 'card_security_viewed',
          parameters: const {'x': 'ecomm'},
        ),
      );
    await pumpAnalyticsTab(tester, core);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'ecomm');
    await tester.pumpAndSettle();

    expect(find.text('card_security_viewed'), findsOneWidget);
    expect(find.text('trx_block_toggle_tapped'), findsNothing);
  });

  testWidgets('opens event details with parameters', (tester) async {
    final core = createCore()
      ..addEvent(
        AliceEvent(
          name: 'trx_block_toggle_tapped',
          parameters: const {'blocking_mode': 'ecommerce'},
        ),
      );
    await pumpAnalyticsTab(tester, core);

    await tester.tap(find.text('trx_block_toggle_tapped'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parameters').last);
    await tester.pumpAndSettle();

    expect(find.text('Alice - Event Details'), findsOneWidget);
    expect(find.text('blocking_mode'), findsOneWidget);
    expect(find.text('ecommerce'), findsOneWidget);
    expect(find.text('Details'), findsNothing);
  });

  testWidgets('shows the extra details tab from the builder', (tester) async {
    final core = createCore(
      eventDetailBuilder: (context, event) =>
          event.name == 'documented' ? const Text('catalog entry') : null,
    )..addEvent(AliceEvent(name: 'documented'));
    await pumpAnalyticsTab(tester, core);

    await tester.tap(find.text('documented'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();

    expect(find.text('catalog entry'), findsOneWidget);
  });

  testWidgets('hides hidden event names until included', (tester) async {
    final core = createCore(hiddenEventNames: const {'rc_parameter'})
      ..addEvent(AliceEvent(name: 'rc_parameter'))
      ..addEvent(AliceEvent(name: 'rc_parameter'))
      ..addEvent(AliceEvent(name: 'card_security_viewed'));
    await pumpAnalyticsTab(tester, core);

    expect(find.text('rc_parameter'), findsNothing);
    expect(find.text('Showing 1 of 3 events'), findsOneWidget);

    await openFilterSheet(tester);
    expect(find.text('Include rc_parameter (2)'), findsOneWidget);
    await tester
        .tap(find.byKey(const Key('events_filter_include_rc_parameter')));
    await applyFilterSheet(tester);

    expect(find.text('rc_parameter'), findsNWidgets(2));
    expect(find.text('Showing 3 of 3 events'), findsOneWidget);
    expect(find.text('Including rc_parameter'), findsOneWidget);
  });

  testWidgets('filters events by several modules', (tester) async {
    final core = createCore()
      ..addEvent(AliceEvent(name: 'card_viewed', module: 'feature_cards'))
      ..addEvent(AliceEvent(name: 'signup_started', module: 'feature_signup'))
      ..addEvent(AliceEvent(name: 'home_viewed', module: 'feature_home'));
    await pumpAnalyticsTab(tester, core);

    await openFilterSheet(tester);
    await tester
        .tap(find.byKey(const Key('events_filter_module_feature_cards')));
    await tester
        .tap(find.byKey(const Key('events_filter_module_feature_home')));
    await applyFilterSheet(tester);

    expect(find.text('card_viewed'), findsOneWidget);
    expect(find.text('home_viewed'), findsOneWidget);
    expect(find.text('signup_started'), findsNothing);
    expect(find.text('Showing 2 of 3 events'), findsOneWidget);
  });

  testWidgets('removes an active filter from its chip', (tester) async {
    final core = createCore()
      ..addEvent(AliceEvent(name: 'card_viewed', module: 'feature_cards'))
      ..addEvent(AliceEvent(name: 'signup_started', module: 'feature_signup'));
    await pumpAnalyticsTab(tester, core);

    await openFilterSheet(tester);
    await tester
        .tap(find.byKey(const Key('events_filter_module_feature_cards')));
    await applyFilterSheet(tester);
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(InputChip, 'Module: feature_cards'),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Showing 2 of 2 events'), findsOneWidget);
    expect(find.byKey(const Key('events_active_filters')), findsNothing);
  });

  testWidgets('clears all filters and shows when nothing matches', (
    tester,
  ) async {
    final core = createCore()
      ..addEvent(AliceEvent(name: 'card_viewed', module: 'feature_cards'))
      ..addEvent(AliceEvent(name: '/cards', category: 'screen'));
    await pumpAnalyticsTab(tester, core);

    await openFilterSheet(tester);
    await tester.tap(find.byKey(const Key('events_filter_category_screen')));
    await tester
        .tap(find.byKey(const Key('events_filter_module_feature_cards')));
    await applyFilterSheet(tester);

    expect(find.text('No events match the filters'), findsOneWidget);

    await tester.tap(find.byKey(const Key('events_clear_all_filters')));
    await tester.pumpAndSettle();

    expect(find.text('Showing 2 of 2 events'), findsOneWidget);
  });

  testWidgets('sorts events by name from the sheet', (tester) async {
    final core = createCore()
      ..addEvent(AliceEvent(name: 'b_event'))
      ..addEvent(AliceEvent(name: 'a_event'));
    await pumpAnalyticsTab(tester, core);

    await openFilterSheet(tester);
    await tester.tap(find.text('Name'));
    await tester.tap(find.byKey(const Key('events_filter_ascending')));
    await applyFilterSheet(tester);

    expect(
      tester.getTopLeft(find.text('a_event')).dy,
      lessThan(tester.getTopLeft(find.text('b_event')).dy),
    );
    expect(find.text('Sorted by name ↑'), findsOneWidget);
  });

  testWidgets('shows the category tag next to the row content', (
    tester,
  ) async {
    final core = createCore()
      ..addEvent(
        AliceEvent(
          name: 'card_viewed',
          category: 'marketing',
          module: 'feature_cards',
          timestamp: DateTime(2026, 10, 20, 12, 1, 10, 864),
        ),
      );
    await pumpAnalyticsTab(tester, core);

    expect(find.text('12:01:10.864 · feature_cards'), findsOneWidget);
    expect(find.text('MARKETING'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('MARKETING')).dx,
      greaterThan(tester.getTopRight(find.text('card_viewed')).dx),
    );
  });

  testWidgets('shows module and logged from in the overview', (tester) async {
    final core = createCore()
      ..addEvent(
        AliceEvent(
          name: 'card_viewed',
          module: 'feature_cards',
          source: 'CardCubit.init\nfeature_cards/lib/src/card_cubit.dart:12',
        ),
      );
    await pumpAnalyticsTab(tester, core);

    await tester.tap(find.text('card_viewed'));
    await tester.pumpAndSettle();

    expect(find.text('Module'), findsOneWidget);
    expect(find.text('feature_cards'), findsOneWidget);
    expect(find.text('Logged from'), findsOneWidget);
    expect(
      find.text('CardCubit.init\nfeature_cards/lib/src/card_cubit.dart:12'),
      findsOneWidget,
    );
  });
}
