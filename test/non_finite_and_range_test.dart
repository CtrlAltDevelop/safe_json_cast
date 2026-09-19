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
  const List<Object> nonFinite = <Object>[
    double.nan,
    double.infinity,
    double.negativeInfinity,
    'NaN',
    'Infinity',
    '-Infinity',
    '1e999',
  ];

  group('non-finite numbers', () {
    for (final Object bad in nonFinite) {
      test('asDouble rejects $bad', () {
        expect(() => asDouble(bad, field: 'f'), throwsCastFor('f'));
      });
      test('asNum rejects $bad', () {
        expect(() => asNum(bad, field: 'f'), throwsCastFor('f'));
      });
      test('asInt rejects $bad with a JsonCastException', () {
        expect(() => asInt(bad, field: 'f'), throwsCastFor('f'));
      });
    }

    test('NaN does not slip past a bound', () {
      expect(
        () => asDouble(double.nan, field: 'f', min: 0, max: 10),
        throwsCastFor('f'),
      );
    });

    test('tryCast now catches them', () {
      expect(tryCast(() => asInt('NaN', field: 'f')), isNull);
      expect(tryCast(() => asDateTime(double.nan, field: 'f')), isNull);
      expect(tryCast(() => asDuration(double.nan, field: 'f')), isNull);
    });

    test('finite values are unaffected', () {
      expect(asDouble('1,234.5', field: 'f'), 1234.5);
      expect(asNum('-7', field: 'f'), -7);
      expect(asInt(1e15, field: 'f'), 1000000000000000);
    });
  });

  group('asInt precision', () {
    test('keeps every digit of a long integer string', () {
      expect(asInt('9007199254740993', field: 'id'), 9007199254740993);
      expect(asInt(' 1,024 ', field: 'id'), 1024);
    });

    test('still truncates a decimal string', () {
      expect(asInt('1,024.9', field: 'id'), 1024);
      expect(asInt('-3.9', field: 'id'), -3);
    });

    test('applies bounds to the exact integer', () {
      expect(() => asInt('101', field: 'p', max: 100), throwsCastFor('p'));
    });
  });

  group('asBool', () {
    test('rejects NaN instead of reading it as true', () {
      expect(() => asBool(double.nan, field: 'f'), throwsCastFor('f'));
    });

    test('keeps the accepted spellings', () {
      for (final String yes in <String>['true', 'T', '1', ' Yes ', 'y']) {
        expect(asBool(yes, field: 'f'), isTrue, reason: yes);
      }
      for (final String no in <String>['false', 'F', '0', 'NO', 'n']) {
        expect(asBool(no, field: 'f'), isFalse, reason: no);
      }
      expect(asBool(2, field: 'f'), isTrue);
      expect(asBool(0.0, field: 'f'), isFalse);
      expect(() => asBool('maybe', field: 'f'), throwsCastFor('f'));
    });
  });

  group('asDateTime range', () {
    test('rejects an epoch DateTime cannot hold instead of a RangeError', () {
      expect(
        () => asDateTime(9e18, field: 'f', unit: EpochUnit.seconds),
        throwsCastFor('f'),
      );
      expect(() => asDateTime(1e17, field: 'f'), throwsCastFor('f'));
      expect(
        () => asDateTime(1e19, field: 'f', unit: EpochUnit.microseconds),
        throwsCastFor('f'),
      );
    });

    test('rejects a multiplication that would wrap around', () {
      // 9.2e15 seconds * 1000 overflows a 64-bit int into a plausible date.
      expect(
        () => asDateTime(9200000000000000, field: 'f', unit: EpochUnit.seconds),
        throwsCastFor('f'),
      );
    });

    test('accepts the edges of the supported range', () {
      expect(
        asDateTime(8640000000000, field: 'f', unit: EpochUnit.seconds),
        DateTime.fromMillisecondsSinceEpoch(8640000000000000, isUtc: true),
      );
      expect(
        asDateTime(-8640000000000000, field: 'f', unit: EpochUnit.milliseconds),
        DateTime.fromMillisecondsSinceEpoch(-8640000000000000, isUtc: true),
      );
    });

    test('still reads ordinary epochs', () {
      final DateTime expected = DateTime.utc(2023, 11, 14, 22, 13, 20);
      expect(asDateTime(1700000000, field: 'f'), expected);
      expect(asDateTime(1700000000000, field: 'f'), expected);
      expect(
        asDateTime(1700000000000000, field: 'f', unit: EpochUnit.microseconds),
        expected,
      );
    });
  });

  group('asDuration range', () {
    test('rejects NaN, infinity and an absurd magnitude', () {
      expect(() => asDuration(double.nan, field: 'f'), throwsCastFor('f'));
      expect(() => asDuration(double.infinity, field: 'f'), throwsCastFor('f'));
      expect(() => asDuration('1e30', field: 'f'), throwsCastFor('f'));
      expect(
        () => asDuration(1e12, field: 'f', unit: DurationUnit.minutes),
        throwsCastFor('f'),
      );
    });

    test('still reads every unit', () {
      expect(asDuration(90, field: 'f'), const Duration(seconds: 90));
      expect(asDuration('1.5', field: 'f'), const Duration(milliseconds: 1500));
      expect(
        asDuration(250, field: 'f', unit: DurationUnit.milliseconds),
        const Duration(milliseconds: 250),
      );
      expect(
        asDuration(7, field: 'f', unit: DurationUnit.microseconds),
        const Duration(microseconds: 7),
      );
      expect(
        asDuration(2, field: 'f', unit: DurationUnit.minutes),
        const Duration(minutes: 2),
      );
    });
  });
}
