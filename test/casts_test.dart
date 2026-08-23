import 'package:safe_json_cast/safe_json_cast.dart';
import 'package:test/test.dart';

/// Matches a [FormatException] whose message mentions [field].
Matcher throwsFieldFormatException(String field) => throwsA(
  isA<FormatException>().having(
    (FormatException e) => e.message,
    'message',
    contains('"$field"'),
  ),
);

void main() {
  group('asString', () {
    test('passes a String through', () {
      expect(asString('BTC', field: 'symbol'), 'BTC');
    });

    test('renders a non-String with toString', () {
      expect(asString(12, field: 'id'), '12');
      expect(asString(true, field: 'flag'), 'true');
      expect(asString(1.5, field: 'rate'), '1.5');
    });

    test('keeps the empty string', () {
      expect(asString('', field: 'memo'), '');
    });

    test('rejects null, naming the field', () {
      expect(
        () => asString(null, field: 'symbol'),
        throwsFieldFormatException('symbol'),
      );
    });
  });

  group('asNullableString', () {
    test('maps null to null', () {
      expect(asNullableString(null, field: 'memo'), isNull);
    });

    test('otherwise behaves like asString', () {
      expect(asNullableString(7, field: 'memo'), '7');
    });
  });

  group('asCleanUrl', () {
    test('strips one leading and one trailing separator', () {
      expect(asCleanUrl('/v1/markets/', field: 'markets'), 'v1/markets');
    });

    test('leaves an already-clean fragment alone', () {
      expect(asCleanUrl('v1/markets', field: 'markets'), 'v1/markets');
    });

    test('strips only a single separator from each end', () {
      expect(asCleanUrl('//v1//', field: 'markets'), '/v1/');
    });

    test('handles a fragment that is only a separator', () {
      expect(asCleanUrl('/', field: 'markets'), '');
    });

    test('rejects null', () {
      expect(
        () => asCleanUrl(null, field: 'markets'),
        throwsFieldFormatException('markets'),
      );
    });

    test('asNullableCleanUrl maps null to null', () {
      expect(asNullableCleanUrl(null, field: 'markets'), isNull);
      expect(asNullableCleanUrl('/v1/', field: 'markets'), 'v1');
    });
  });

  group('asDouble', () {
    test('accepts any num', () {
      expect(asDouble(2, field: 'price'), 2.0);
      expect(asDouble(2.5, field: 'price'), 2.5);
      expect(asDouble(-3, field: 'price'), -3.0);
    });

    test('parses a decimal string', () {
      expect(asDouble('64120.55', field: 'price'), 64120.55);
    });

    test('strips grouping commas and surrounding whitespace', () {
      expect(asDouble(' 1,234.5 ', field: 'price'), 1234.5);
    });

    test('rejects a non-numeric string, quoting the value', () {
      expect(
        () => asDouble('n/a', field: 'price'),
        throwsA(
          isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            allOf(contains('"price"'), contains('n/a')),
          ),
        ),
      );
    });

    test('rejects null and other types', () {
      expect(
        () => asDouble(null, field: 'price'),
        throwsFieldFormatException('price'),
      );
      expect(
        () => asDouble(<int>[1], field: 'price'),
        throwsFieldFormatException('price'),
      );
    });

    test('asNullableDouble maps null to null', () {
      expect(asNullableDouble(null, field: 'price'), isNull);
    });
  });

  group('asInt', () {
    test('passes an int through', () {
      expect(asInt(42, field: 'count'), 42);
    });

    test('truncates a non-int num toward zero', () {
      expect(asInt(42.9, field: 'count'), 42);
      expect(asInt(-42.9, field: 'count'), -42);
    });

    test('parses a string, truncating any fraction', () {
      expect(asInt('1,024.9', field: 'count'), 1024);
    });

    test('rejects a non-numeric string', () {
      expect(
        () => asInt('many', field: 'count'),
        throwsFieldFormatException('count'),
      );
    });

    test('asNullableInt maps null to null', () {
      expect(asNullableInt(null, field: 'count'), isNull);
    });
  });

  group('asBool', () {
    test('passes a bool through', () {
      expect(asBool(true, field: 'tradable'), isTrue);
      expect(asBool(false, field: 'tradable'), isFalse);
    });

    test('reads a num as non-zero', () {
      expect(asBool(1, field: 'tradable'), isTrue);
      expect(asBool(0, field: 'tradable'), isFalse);
      expect(asBool(-1, field: 'tradable'), isTrue);
    });

    test('accepts the truthy spellings, case-insensitively', () {
      for (final raw in <String>['true', 'T', '1', 'yes', ' Y ']) {
        expect(asBool(raw, field: 'tradable'), isTrue, reason: raw);
      }
    });

    test('accepts the falsy spellings, case-insensitively', () {
      for (final raw in <String>['false', 'F', '0', 'no', ' N ']) {
        expect(asBool(raw, field: 'tradable'), isFalse, reason: raw);
      }
    });

    test('rejects an unrecognised string', () {
      expect(
        () => asBool('maybe', field: 'tradable'),
        throwsFieldFormatException('tradable'),
      );
    });

    test('asNullableBool maps null to null', () {
      expect(asNullableBool(null, field: 'tradable'), isNull);
    });
  });

  group('asDateTime', () {
    test('passes a DateTime through', () {
      final now = DateTime.utc(2026, 8, 23);
      expect(asDateTime(now, field: 'at'), now);
    });

    test('parses an ISO 8601 string, keeping its zone', () {
      expect(
        asDateTime('2026-08-23T09:15:00Z', field: 'at'),
        DateTime.utc(2026, 8, 23, 9, 15),
      );
    });

    test('trims surrounding whitespace', () {
      expect(
        asDateTime(' 2026-08-23T09:15:00Z ', field: 'at'),
        DateTime.utc(2026, 8, 23, 9, 15),
      );
    });

    test('reads a large num as epoch milliseconds, in UTC', () {
      final at = asDateTime(1766500000000, field: 'at');
      expect(
        at,
        DateTime.fromMillisecondsSinceEpoch(1766500000000, isUtc: true),
      );
      expect(at.isUtc, isTrue);
    });

    test('reads a small num as epoch seconds, in UTC', () {
      final at = asDateTime(1766500000, field: 'at');
      expect(
        at,
        DateTime.fromMillisecondsSinceEpoch(1766500000000, isUtc: true),
      );
      expect(at.isUtc, isTrue);
    });

    test('reads a negative millisecond epoch as milliseconds', () {
      // 1e12 ms before the epoch, well outside the seconds range.
      expect(
        asDateTime(-1766500000000, field: 'at'),
        DateTime.fromMillisecondsSinceEpoch(-1766500000000, isUtc: true),
      );
    });

    test('rejects an unparseable string', () {
      expect(
        () => asDateTime('yesterday', field: 'at'),
        throwsFieldFormatException('at'),
      );
    });

    test('asNullableDateTime maps null to null', () {
      expect(asNullableDateTime(null, field: 'at'), isNull);
    });
  });

  group('asMap', () {
    test('passes a JSON object through', () {
      final json = <String, dynamic>{'a': 1};
      expect(asMap(json, field: 'nested'), same(json));
    });

    test('casts a differently-typed map whose keys are all Strings', () {
      final loose = <Object, Object>{'a': 1};
      expect(asMap(loose, field: 'nested'), <String, dynamic>{'a': 1});
    });

    test('rejects a map with a non-String key', () {
      expect(
        () => asMap(<Object, Object>{1: 'a'}, field: 'nested'),
        throwsFieldFormatException('nested'),
      );
    });

    test('rejects a non-map, naming the field', () {
      expect(
        () => asMap(<int>[1], field: 'nested'),
        throwsFieldFormatException('nested'),
      );
      expect(
        () => asMap(null, field: 'nested'),
        throwsFieldFormatException('nested'),
      );
    });

    test('asNullableMap maps null to null', () {
      expect(asNullableMap(null, field: 'nested'), isNull);
    });
  });

  group('asList', () {
    test('converts every element', () {
      expect(
        asList<double>(
          <Object?>['1.5', 2, 3.5],
          field: 'prices',
          element: (Object? raw, String field) => asDouble(raw, field: field),
        ),
        <double>[1.5, 2.0, 3.5],
      );
    });

    test('returns an empty list for an empty array', () {
      expect(
        asList<double>(
          <Object?>[],
          field: 'prices',
          element: (Object? raw, String field) => asDouble(raw, field: field),
        ),
        isEmpty,
      );
    });

    test('names the failing element by index', () {
      expect(
        () => asList<double>(
          <Object?>[1, 'oops'],
          field: 'prices',
          element: (Object? raw, String field) => asDouble(raw, field: field),
        ),
        throwsFieldFormatException('prices[1]'),
      );
    });

    test('rejects a non-list', () {
      expect(
        () => asList<double>(
          <String, dynamic>{},
          field: 'prices',
          element: (Object? raw, String field) => asDouble(raw, field: field),
        ),
        throwsFieldFormatException('prices'),
      );
    });

    test('returns a fixed-length list', () {
      final prices = asList<double>(
        <Object?>[1],
        field: 'prices',
        element: (Object? raw, String field) => asDouble(raw, field: field),
      );
      expect(() => prices.add(2), throwsUnsupportedError);
    });

    test('asNullableList maps null to null', () {
      expect(
        asNullableList<double>(
          null,
          field: 'prices',
          element: (Object? raw, String field) => asDouble(raw, field: field),
        ),
        isNull,
      );
    });
  });
}
