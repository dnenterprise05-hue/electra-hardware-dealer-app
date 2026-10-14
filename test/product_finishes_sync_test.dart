import 'package:flutter_test/flutter_test.dart';
import 'package:electra_hardware/product_details_screen.dart';

void main() {
  group('parseProductFinishes — finish sync from Firestore', () {
    test('returns all finishes when product has full selection', () {
      final data = {
        'finishes': [
          'CP',
          'SATIN',
          'ANTIQUE',
          'GOLD',
          'ROSEGOLD',
          'Z.BLACK',
          'B.SATIN',
        ],
      };
      final result =
          ProductDetailsScreen.parseProductFinishes(data);
      expect(result, hasLength(7));
      expect(result, contains('CP'));
      expect(result, contains('Z.BLACK'));
    });

    test(
        'returns reduced list after admin deselects a finish '
        '(the reported bug)', () {
      // Admin deselected Z.BLACK and saved.
      final data = {
        'finishes': [
          'CP',
          'SATIN',
          'ANTIQUE',
          'GOLD',
          'ROSEGOLD',
          'B.SATIN',
        ],
      };
      final result =
          ProductDetailsScreen.parseProductFinishes(data);
      expect(result, hasLength(6));
      expect(result, isNot(contains('Z.BLACK')));
      expect(result, contains('CP'));
    });

    test('returns null for legacy product without finishes field',
        () {
      final result =
          ProductDetailsScreen.parseProductFinishes({});
      expect(result, isNull);
    });

    test('returns null for null product data', () {
      final result =
          ProductDetailsScreen.parseProductFinishes(null);
      expect(result, isNull);
    });

    test('returns null for empty finishes list (treated as legacy)',
        () {
      // Admin Panel blocks empty saves via "Select At Least One Finish"
      // validation, so empty only occurs from legacy/manual data.
      // Falling back to the default list keeps the finish selector
      // and cart flow functional.
      final result = ProductDetailsScreen.parseProductFinishes(
          {'finishes': []});
      expect(result, isNull);
    });

    test('trims whitespace and drops empty entries', () {
      final data = {
        'finishes': ['  CP  ', '', 'SATIN', '   '],
      };
      final result =
          ProductDetailsScreen.parseProductFinishes(data);
      expect(result, ['CP', 'SATIN']);
    });
  });
}
