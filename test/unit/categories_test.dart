import 'package:flutter_test/flutter_test.dart';
import 'package:tour_buddy/constants/categories.dart';

void main() {
  group('TripCategories', () {
    test('contains Food category', () {
      expect(TripCategories.food, 'Food');
    });

    test('contains Transport category', () {
      expect(TripCategories.transport, 'Transport');
    });

    test('contains Hotel category', () {
      expect(TripCategories.hotel, 'Hotel');
    });

    test('contains Shopping category', () {
      expect(TripCategories.shopping, 'Shopping');
    });

    test('contains Other category', () {
      expect(TripCategories.other, 'Other');
    });

    test('defaultList contains all 5 categories', () {
      expect(TripCategories.defaultList, hasLength(5));
    });

    test('defaultList contains Food', () {
      expect(TripCategories.defaultList, contains('Food'));
    });

    test('defaultList contains Transport', () {
      expect(TripCategories.defaultList, contains('Transport'));
    });

    test('defaultList contains Hotel', () {
      expect(TripCategories.defaultList, contains('Hotel'));
    });

    test('defaultList contains Shopping', () {
      expect(TripCategories.defaultList, contains('Shopping'));
    });

    test('defaultList contains Other', () {
      expect(TripCategories.defaultList, contains('Other'));
    });

    test('defaultList has no duplicates', () {
      final unique = TripCategories.defaultList.toSet();
      expect(unique.length, TripCategories.defaultList.length);
    });

    test('all category strings are non-empty', () {
      for (final cat in TripCategories.defaultList) {
        expect(cat, isNotEmpty);
      }
    });

    test('static constants match defaultList entries', () {
      expect(TripCategories.defaultList[0], TripCategories.food);
      expect(TripCategories.defaultList[1], TripCategories.transport);
      expect(TripCategories.defaultList[2], TripCategories.hotel);
      expect(TripCategories.defaultList[3], TripCategories.shopping);
      expect(TripCategories.defaultList[4], TripCategories.other);
    });
  });
}
