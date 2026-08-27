import 'package:safe_json_cast/safe_json_cast.dart';
import 'package:test/test.dart';

enum OrderStatus { newOrder, filled, partiallyFilled }

/// Matches a [JsonCastException] carrying [field].
Matcher throwsCastFor(String field) => throwsA(
  isA<JsonCastException>().having(
    (JsonCastException e) => e.field,
    'field',
    field,
  ),
);

void main() {
  group('JsonCastException', () {
    test('is still a FormatException', () {
      expect(
        () => asDouble('n/a', field: 'fee'),
        throwsA(isA<FormatException>()),
      );
    });

    test('carries the field, value and expected type', () {
      try {
        asDouble('n/a', field: 'fee');
        fail('expected a throw');
      } on JsonCastException catch (e) {
        expect(e.field, 'fee');
        expect(e.value, 'n/a');
        expect(e.expectedType, 'double');
        expect(e.message, 'Field "fee"="n/a" cannot be parsed as double.');
      }
    });

    test('keeps the null-value message unchanged', () {
      try {
        asString(null, field: 'symbol');
        fail('expected a throw');
      } on JsonCastException catch (e) {
        expect(e.message, 'Field "symbol" is null, expected String.');
        expect(e.value, isNull);
      }
    });
  });

  group('asNum', () {
    test('keeps an int an int', () {
      expect(asNum(3, field: 'qty'), isA<int>());
      expect(asNum('3', field: 'qty'), 3);
      expect(asNum(' 1,234.5 ', field: 'qty'), 1234.5);
    });

    test('rejects a non-numeric string', () {
      expect(() => asNum('n/a', field: 'qty'), throwsCastFor('qty'));
    });

    test('maps null to null in the nullable form', () {
      expect(asNullableNum(null, field: 'qty'), isNull);
    });
  });

  group('asBigInt', () {
    test('parses a string past the 64-bit range', () {
      expect(
        asBigInt('123456789012345678901', field: 'id'),
        BigInt.parse('123456789012345678901'),
      );
    });

    test('accepts an int and an integral double', () {
      expect(asBigInt(12, field: 'id'), BigInt.from(12));
      expect(asBigInt(12.0, field: 'id'), BigInt.from(12));
    });

    test('strips grouping commas', () {
      expect(asBigInt('1,024', field: 'id'), BigInt.from(1024));
    });

    test('rejects a fractional value rather than truncating', () {
      expect(() => asBigInt(1.5, field: 'id'), throwsCastFor('id'));
      expect(() => asBigInt('1.5', field: 'id'), throwsCastFor('id'));
    });

    test('maps null to null in the nullable form', () {
      expect(asNullableBigInt(null, field: 'id'), isNull);
    });
  });

  group('asUri', () {
    test('parses a string', () {
      expect(asUri(' https://a.test/x ', field: 'url').host, 'a.test');
    });

    test('passes a Uri through', () {
      final Uri uri = Uri.parse('https://a.test');
      expect(asUri(uri, field: 'url'), same(uri));
    });

    test('rejects a malformed string', () {
      expect(() => asUri('http://[', field: 'url'), throwsCastFor('url'));
    });

    test('rejects null, naming the field', () {
      expect(() => asUri(null, field: 'url'), throwsCastFor('url'));
      expect(asNullableUri(null, field: 'url'), isNull);
    });
  });

  group('asEnum', () {
    test('matches a name case-insensitively', () {
      expect(
        asEnum('FILLED', field: 'status', values: OrderStatus.values),
        OrderStatus.filled,
      );
      expect(
        asEnum(' filled ', field: 'status', values: OrderStatus.values),
        OrderStatus.filled,
      );
    });

    test('prefers a wire name', () {
      expect(
        asEnum(
          'PARTIALLY_FILLED',
          field: 'status',
          values: OrderStatus.values,
          wireNames: const <String, OrderStatus>{
            'PARTIALLY_FILLED': OrderStatus.partiallyFilled,
          },
        ),
        OrderStatus.partiallyFilled,
      );
    });

    test('lists the accepted names when nothing matches', () {
      try {
        asEnum('CANCELED', field: 'status', values: OrderStatus.values);
        fail('expected a throw');
      } on JsonCastException catch (e) {
        expect(e.message, contains('"status"="CANCELED"'));
        expect(e.message, contains('filled'));
      }
    });

    test('maps null to null in the nullable form', () {
      expect(
        asNullableEnum(null, field: 'status', values: OrderStatus.values),
        isNull,
      );
    });
  });

  group('asMapOf', () {
    test('converts every value and names the failing key', () {
      final Map<String, double> balances = asMapOf<double>(
        <String, dynamic>{'BTC': '0.5', 'ETH': 2},
        field: 'balances',
        entry: (Object? raw, String field) => asDouble(raw, field: field),
      );
      expect(balances, <String, double>{'BTC': 0.5, 'ETH': 2});

      try {
        asMapOf<double>(
          <String, dynamic>{'BTC': 'n/a'},
          field: 'balances',
          entry: (Object? raw, String field) => asDouble(raw, field: field),
        );
        fail('expected a throw');
      } on JsonCastException catch (e) {
        expect(e.field, 'balances.BTC');
      }
    });

    test('rejects a non-object, naming the field', () {
      expect(
        () => asMapOf<double>(
          <int>[1],
          field: 'balances',
          entry: (Object? raw, String field) => asDouble(raw, field: field),
        ),
        throwsCastFor('balances'),
      );
      expect(
        asNullableMapOf<double>(
          null,
          field: 'balances',
          entry: (Object? raw, String field) => asDouble(raw, field: field),
        ),
        isNull,
      );
    });
  });

  group('asDateTime unit', () {
    test('reads a small number as milliseconds when told to', () {
      expect(
        asDateTime(1000, field: 'ts', unit: EpochUnit.milliseconds),
        DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
      );
    });

    test('reads a large number as seconds when told to', () {
      expect(
        asDateTime(1000000000000, field: 'ts', unit: EpochUnit.seconds).year,
        33658,
      );
    });

    test('reads microseconds', () {
      expect(
        asDateTime(1500000, field: 'ts', unit: EpochUnit.microseconds),
        DateTime.fromMicrosecondsSinceEpoch(1500000, isUtc: true),
      );
    });

    test('still guesses by default', () {
      expect(
        asDateTime(1700000000, field: 'ts'),
        DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
      );
    });
  });

  group('tryCast', () {
    test('returns the value when the cast succeeds', () {
      expect(tryCast(() => asDouble('1.5', field: 'fee')), 1.5);
    });

    test('returns null when it fails', () {
      expect(tryCast(() => asDouble('n/a', field: 'fee')), isNull);
    });

    test('lets a non-FormatException through', () {
      expect(
        () => tryCast<int>(() => throw StateError('boom')),
        throwsStateError,
      );
    });
  });

  group('asList growable', () {
    test('is fixed-length by default and growable on request', () {
      final List<int> fixed = asList<int>(
        <int>[1],
        field: 'xs',
        element: (Object? raw, String field) => asInt(raw, field: field),
      );
      expect(() => fixed.add(2), throwsUnsupportedError);

      final List<int> grown = asList<int>(
        <int>[1],
        field: 'xs',
        element: (Object? raw, String field) => asInt(raw, field: field),
        growable: true,
      );
      expect(grown..add(2), <int>[1, 2]);
    });
  });

  group('SafeJsonMap additions', () {
    final Map<String, dynamic> json = <String, dynamic>{
      'qty': '2',
      'id': '123456789012345678901',
      'url': 'https://a.test',
      'status': 'FILLED',
      'balances': <String, dynamic>{'BTC': '0.5'},
      'sizes': <dynamic>['1', 2],
      'prices': <dynamic>['1.5', 2],
      'ts': 1000,
    };

    test('mirror the bare casts', () {
      expect(json.asNum('qty'), 2);
      expect(json.asBigInt('id'), BigInt.parse('123456789012345678901'));
      expect(json.asUri('url').host, 'a.test');
      expect(
        json.asEnum('status', values: OrderStatus.values),
        OrderStatus.filled,
      );
      expect(
        json.asMapOf<double>(
          'balances',
          entry: (Object? raw, String field) => asDouble(raw, field: field),
        ),
        <String, double>{'BTC': 0.5},
      );
      expect(json.asIntList('sizes'), <int>[1, 2]);
      expect(json.asDoubleList('prices'), <double>[1.5, 2]);
      expect(
        json.asDateTime('ts', unit: EpochUnit.milliseconds),
        DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
      );
    });

    test('return null for an absent key in the nullable forms', () {
      expect(json.asNullableNum('missing'), isNull);
      expect(json.asNullableBigInt('missing'), isNull);
      expect(json.asNullableUri('missing'), isNull);
      expect(
        json.asNullableEnum('missing', values: OrderStatus.values),
        isNull,
      );
      expect(
        json.asNullableMapOf<double>(
          'missing',
          entry: (Object? raw, String field) => asDouble(raw, field: field),
        ),
        isNull,
      );
    });

    test('name the failing element inside a typed list', () {
      try {
        (<String, dynamic>{
          'sizes': <dynamic>[1, 'n/a'],
        }).asIntList('sizes');
        fail('expected a throw');
      } on JsonCastException catch (e) {
        expect(e.field, 'sizes[1]');
      }
    });
  });
}
