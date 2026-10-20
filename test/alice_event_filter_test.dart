import 'package:alice/alice.dart';
import 'package:alice/src/model/alice_event_filter.dart';
import 'package:alice/src/model/alice_event_sort_option.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cardViewed = AliceEvent(name: 'card_viewed', module: 'feature_cards');
  final signupStarted = AliceEvent(
    name: 'signup_started',
    category: 'marketing',
    module: 'feature_signup',
  );
  final rcParameter = AliceEvent(name: 'rc_parameter', module: 'klar_config');
  final cardsScreen = AliceEvent(
    name: '/cards',
    category: 'screen',
    module: 'feature_cards',
  );
  final events = [cardViewed, signupStarted, rcParameter, cardsScreen];

  List<AliceEvent> apply(AliceEventFilter filter, {String query = ''}) =>
      filter.apply(
        events,
        hiddenEventNames: const {'rc_parameter'},
        query: query,
      );

  group('AliceEventFilter', () {
    test('by default hides hidden names and sorts newest first', () {
      expect(
        apply(const AliceEventFilter()),
        [cardsScreen, signupStarted, cardViewed],
      );
    });

    test('includes hidden names when selected', () {
      expect(
        apply(const AliceEventFilter(includedHiddenNames: {'rc_parameter'})),
        contains(rcParameter),
      );
    });

    test('matches any of the selected categories', () {
      expect(
        apply(const AliceEventFilter(categories: {'marketing', 'screen'})),
        [cardsScreen, signupStarted],
      );
    });

    test('matches any of the selected modules and categories together', () {
      expect(
        apply(
          const AliceEventFilter(
            categories: {'event'},
            modules: {'feature_cards', 'feature_signup'},
          ),
        ),
        [cardViewed],
      );
    });

    test('combines filters with the search query', () {
      expect(
        apply(
          const AliceEventFilter(modules: {'feature_cards'}),
          query: 'card',
        ),
        [cardsScreen, cardViewed],
      );
    });

    test('sorts by name in both directions', () {
      const byName = AliceEventFilter(sortOption: AliceEventSortOption.name);

      expect(apply(byName), [signupStarted, cardViewed, cardsScreen]);
      expect(
        apply(byName.copyWith(sortAscending: true)),
        [cardsScreen, cardViewed, signupStarted],
      );
    });

    test('counts active filters and a non default sort', () {
      const filter = AliceEventFilter(
        categories: {'event', 'screen'},
        modules: {'feature_cards'},
        includedHiddenNames: {'rc_parameter'},
        sortAscending: true,
      );

      expect(filter.activeFilterCount, 5);
      expect(filter.isDefault, isFalse);
      expect(const AliceEventFilter().activeFilterCount, 0);
      expect(const AliceEventFilter().isDefault, isTrue);
    });
  });
}
