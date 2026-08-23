import 'package:safe_json_cast/safe_json_cast.dart';
import 'package:test/test.dart';

void main() {
  final json = <String, dynamic>{
    'symbol': 'BTCUSDT',
    'lastPrice': '64,120.55',
    'count': 42.9,
    'tradable': 1,
    'updateTime': 1766500000000,
    'note': null,
    'base': '/v1/markets/',
    'nested': <String, dynamic>{'price': 1.5},
    'tags': <Object?>['spot', 'futures'],
    'levels': <Object?>[
      <String, dynamic>{'price': 1.0},
      <String, dynamic>{'price': 2.0},
    ],
  };

  test('reads each type off the map with the key as the field name', () {
    expect(json.asString('symbol'), 'BTCUSDT');
    expect(json.asDouble('lastPrice'), 64120.55);
    expect(json.asInt('count'), 42);
    expect(json.asBool('tradable'), isTrue);
    expect(json.asCleanUrl('base'), 'v1/markets');
    expect(
      json.asDateTime('updateTime'),
      DateTime.fromMillisecondsSinceEpoch(1766500000000, isUtc: true),
    );
    expect(json.asMap('nested'), <String, dynamic>{'price': 1.5});
  });

  test('a present null reads as null through a nullable cast', () {
    expect(json.asNullableString('note'), isNull);
    expect(json.asNullableDouble('note'), isNull);
    expect(json.asNullableInt('note'), isNull);
    expect(json.asNullableBool('note'), isNull);
    expect(json.asNullableDateTime('note'), isNull);
    expect(json.asNullableMap('note'), isNull);
    expect(json.asNullableCleanUrl('note'), isNull);
  });

  test('an absent key behaves like a present null', () {
    expect(json.asNullableString('missing'), isNull);
    expect(json.asNullableDouble('missing'), isNull);
    expect(
      () => json.asString('missing'),
      throwsA(
        isA<FormatException>().having(
          (FormatException e) => e.message,
          'message',
          contains('"missing"'),
        ),
      ),
    );
  });

  test('hasKey tells an absent key from a present null', () {
    expect(json.hasKey('note'), isTrue);
    expect(json.hasKey('missing'), isFalse);
  });

  test('the failure message names the key that was read', () {
    expect(
      () => json.asDouble('symbol'),
      throwsA(
        isA<FormatException>().having(
          (FormatException e) => e.message,
          'message',
          allOf(contains('"symbol"'), contains('BTCUSDT')),
        ),
      ),
    );
  });

  test('asStringList reads a list of strings', () {
    expect(json.asStringList('tags'), <String>['spot', 'futures']);
  });

  test('asMapList reads a list of nested objects', () {
    expect(json.asMapList('levels'), <Map<String, dynamic>>[
      <String, dynamic>{'price': 1.0},
      <String, dynamic>{'price': 2.0},
    ]);
  });

  test('asList applies the element cast and indexes the field name', () {
    expect(
      json.asList<double>(
        'levels',
        element: (Object? raw, String field) =>
            asDouble(asMap(raw, field: field)['price'], field: '$field.price'),
      ),
      <double>[1.0, 2.0],
    );

    final broken = <String, dynamic>{
      'levels': <Object?>[
        <String, dynamic>{'price': 1.0},
        <String, dynamic>{'price': 'oops'},
      ],
    };
    expect(
      () => broken.asList<double>(
        'levels',
        element: (Object? raw, String field) =>
            asDouble(asMap(raw, field: field)['price'], field: '$field.price'),
      ),
      throwsA(
        isA<FormatException>().having(
          (FormatException e) => e.message,
          'message',
          contains('"levels[1].price"'),
        ),
      ),
    );
  });

  test('asNullableList maps an absent key to null', () {
    expect(
      json.asNullableList<String>(
        'missing',
        element: (Object? raw, String field) => asString(raw, field: field),
      ),
      isNull,
    );
  });

  test('applies to a Map<String, Object?> receiver as well', () {
    final typed = <String, Object?>{'symbol': 'ETHUSDT'};
    expect(typed.asString('symbol'), 'ETHUSDT');
  });
}
