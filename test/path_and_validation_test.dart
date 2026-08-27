import 'package:safe_json_cast/safe_json_cast.dart';
import 'package:test/test.dart';

/// Matches a [JsonCastException] carrying [field].
Matcher throwsCastFor(String field) => throwsA(
  isA<JsonCastException>().having(
    (JsonCastException e) => e.field,
    'field',
    field,
  ),
);

void main() {
  group('numeric bounds', () {
    test('accept a value inside an inclusive range', () {
      expect(asDouble('50', field: 'pct', min: 0, max: 100), 50);
      expect(asDouble(0, field: 'pct', min: 0, max: 100), 0);
      expect(asDouble(100, field: 'pct', min: 0, max: 100), 100);
      expect(asInt('3', field: 'qty', min: 1), 3);
      expect(asNum(2, field: 'qty', max: 2), 2);
    });

    test('reject a value below the minimum, quoting the raw value', () {
      try {
        asDouble('-1', field: 'qty', min: 0);
        fail('expected a throw');
      } on JsonCastException catch (e) {
        expect(e.field, 'qty');
        expect(e.value, '-1');
        expect(e.message, 'Field "qty"="-1" is outside the minimum 0.');
      }
    });

    test('reject a value above the maximum', () {
      expect(() => asInt(101, field: 'pct', max: 100), throwsCastFor('pct'));
      expect(
        () => asNum(101, field: 'pct', min: 0, max: 100),
        throwsA(
          isA<JsonCastException>().having(
            (JsonCastException e) => e.message,
            'message',
            contains('the range 0..100'),
          ),
        ),
      );
    });

    test('check after conversion, so truncation is what is bounded', () {
      expect(asInt('1.9', field: 'qty', max: 1), 1);
    });

    test('are checked by the nullable forms too, and skip null', () {
      expect(asNullableInt(null, field: 'qty', min: 5), isNull);
      expect(
        () => asNullableInt(1, field: 'qty', min: 5),
        throwsCastFor('qty'),
      );
    });
  });

  group('asStrictString', () {
    test('passes a String through', () {
      expect(asStrictString('BTC', field: 'symbol'), 'BTC');
    });

    test('rejects what asString would have coerced', () {
      expect(asString(12, field: 'id'), '12');
      expect(() => asStrictString(12, field: 'id'), throwsCastFor('id'));
      expect(() => asStrictString(null, field: 'id'), throwsCastFor('id'));
      expect(asNullableStrictString(null, field: 'id'), isNull);
    });
  });

  group('asNonEmptyString', () {
    test('passes a filled string through untrimmed by default', () {
      expect(asNonEmptyString(' BTC ', field: 'symbol'), ' BTC ');
      expect(asNonEmptyString(' BTC ', field: 'symbol', trim: true), 'BTC');
    });

    test('rejects an empty or whitespace-only string', () {
      expect(() => asNonEmptyString('', field: 'id'), throwsCastFor('id'));
      expect(() => asNonEmptyString('   ', field: 'id'), throwsCastFor('id'));
    });

    test('rejects an empty string in the nullable form too', () {
      expect(asNullableNonEmptyString(null, field: 'id'), isNull);
      expect(
        () => asNullableNonEmptyString('', field: 'id'),
        throwsCastFor('id'),
      );
    });

    test('pairs with tryCast when null is the wanted outcome', () {
      expect(tryCast(() => asNonEmptyString('', field: 'id')), isNull);
    });
  });

  group('asDuration', () {
    test('reads a number in the stated unit, seconds by default', () {
      expect(asDuration(3600, field: 'expiresIn'), const Duration(hours: 1));
      expect(
        asDuration(1500, field: 'ttl', unit: DurationUnit.milliseconds),
        const Duration(milliseconds: 1500),
      );
      expect(
        asDuration(90, field: 'ttl', unit: DurationUnit.minutes),
        const Duration(minutes: 90),
      );
      expect(
        asDuration(250, field: 'ttl', unit: DurationUnit.microseconds),
        const Duration(microseconds: 250),
      );
    });

    test('reads a numeric string the same way', () {
      expect(asDuration('3,600', field: 'expiresIn'), const Duration(hours: 1));
    });

    test('keeps a fraction to microsecond precision', () {
      expect(asDuration(1.5, field: 'ttl'), const Duration(milliseconds: 1500));
    });

    test('passes a Duration through', () {
      expect(
        asDuration(const Duration(seconds: 2), field: 'ttl'),
        const Duration(seconds: 2),
      );
    });

    test('rejects an unparseable value, naming the field', () {
      expect(() => asDuration('n/a', field: 'ttl'), throwsCastFor('ttl'));
      expect(() => asDuration(null, field: 'ttl'), throwsCastFor('ttl'));
      expect(asNullableDuration(null, field: 'ttl'), isNull);
    });
  });

  group('asSet', () {
    Set<String> read(Object? raw, {bool allowDuplicates = true}) => asSet(
      raw,
      field: 'tags',
      element: (Object? element, String field) =>
          asString(element, field: field),
      allowDuplicates: allowDuplicates,
    );

    test('converts elements and keeps their order', () {
      expect(read(<String>['b', 'a']).toList(), <String>['b', 'a']);
    });

    test('collapses a duplicate by default', () {
      expect(read(<String>['a', 'a']), <String>{'a'});
    });

    test('rejects a duplicate on request, naming the repeated entry', () {
      expect(
        () => read(<String>['a', 'b', 'a'], allowDuplicates: false),
        throwsCastFor('tags[2]'),
      );
    });

    test('rejects a non-list and names the failing element', () {
      expect(() => read(<String, dynamic>{}), throwsCastFor('tags'));
      expect(
        () => asSet<int>(
          <dynamic>[1, 'n/a'],
          field: 'sizes',
          element: (Object? element, String field) =>
              asInt(element, field: field),
        ),
        throwsCastFor('sizes[1]'),
      );
    });

    test('maps null to null in the nullable form', () {
      expect(
        asNullableSet<String>(
          null,
          field: 'tags',
          element: (Object? element, String field) =>
              asString(element, field: field),
        ),
        isNull,
      );
    });
  });

  group('paths', () {
    final Map<String, dynamic> json = <String, dynamic>{
      'data': <String, dynamic>{
        'orders': <dynamic>[
          <String, dynamic>{'price': '1.5', 'memo': null},
          <String, dynamic>{'price': 'n/a'},
        ],
        'user': <String, dynamic>{'name': 'ada'},
      },
      'grid': <dynamic>[
        <dynamic>[1, 2],
      ],
      'label': 'flat',
    };

    test('walks objects and array indices', () {
      expect(json.valueAt('data.user.name'), 'ada');
      expect(json.valueAt('data.orders[0].price'), '1.5');
      expect(json.valueAt('grid[0][1]'), 2);
      expect(json.valueAt('label'), 'flat');
    });

    test('resolves an absent key or index to null', () {
      expect(json.valueAt('data.user.email'), isNull);
      expect(json.valueAt('data.orders[9].price'), isNull);
      expect(json.valueAt('missing.deeply.nested'), isNull);
    });

    test('throws when a present step cannot be walked', () {
      expect(() => json.valueAt('label.name'), throwsCastFor('label'));
      expect(() => json.valueAt('data.user[0]'), throwsCastFor('data.user'));
    });

    test('rejects a malformed index', () {
      expect(() => json.valueAt('grid[x]'), throwsCastFor('grid[x]'));
    });

    test('castAt reports the whole path as the field name', () {
      expect(json.castAt('data.orders[0].price', asDouble), 1.5);
      expect(
        () => json.castAt('data.orders[1].price', asDouble),
        throwsCastFor('data.orders[1].price'),
      );
      expect(json.castAt('data.user.email', asNullableString), isNull);
    });

    test('hasPath tells an absent path from a present null one', () {
      expect(json.hasPath('data.orders[0].memo'), isTrue);
      expect(json.hasPath('data.orders[0].price'), isTrue);
      expect(json.hasPath('data.orders[0].missing'), isFalse);
      expect(json.hasPath('data.orders[9]'), isFalse);
      expect(json.hasPath('label'), isTrue);
      expect(json.hasPath('missing'), isFalse);
      expect(json.hasPath('missing.deeply'), isFalse);
    });

    test('the bare functions work on any decoded root', () {
      expect(valueAtPath(json, 'data.user.name'), 'ada');
      expect(pathExists(json, 'data.user.name'), isTrue);
    });
  });

  group('SafeJsonMap additions', () {
    final Map<String, dynamic> json = <String, dynamic>{
      'symbol': 'BTC',
      'id': 12,
      'ttl': 3600,
      'tags': <dynamic>['spot', 'spot', 'futures'],
      'pct': 150,
    };

    test('mirror the bare casts', () {
      expect(json.asStrictString('symbol'), 'BTC');
      expect(() => json.asStrictString('id'), throwsCastFor('id'));
      expect(json.asNonEmptyString('symbol'), 'BTC');
      expect(json.asDuration('ttl'), const Duration(hours: 1));
      expect(json.asStringSet('tags'), <String>{'spot', 'futures'});
      expect(
        () => json.asStringSet('tags', allowDuplicates: false),
        throwsCastFor('tags[1]'),
      );
      expect(
        json.asSet<int>(
          'tags',
          element: (Object? raw, String field) => raw.hashCode,
        ),
        hasLength(2),
      );
      expect(() => json.asInt('pct', max: 100), throwsCastFor('pct'));
    });

    test('return null for an absent key in the nullable forms', () {
      expect(json.asNullableStrictString('missing'), isNull);
      expect(json.asNullableNonEmptyString('missing'), isNull);
      expect(json.asNullableDuration('missing'), isNull);
      expect(
        json.asNullableSet<String>(
          'missing',
          element: (Object? raw, String field) => asString(raw, field: field),
        ),
        isNull,
      );
    });
  });
}
