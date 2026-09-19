# safe_json_cast

[![pub package](https://img.shields.io/pub/v/safe_json_cast.svg)](https://pub.dev/packages/safe_json_cast)
[![pub points](https://img.shields.io/pub/points/safe_json_cast)](https://pub.dev/packages/safe_json_cast/score)
[![CI](https://github.com/CtrlAltDevelop/safe_json_cast/actions/workflows/ci.yml/badge.svg)](https://github.com/CtrlAltDevelop/safe_json_cast/actions/workflows/ci.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/CtrlAltDevelop/safe_json_cast/blob/main/LICENSE)

Typed casts for decoded JSON that **fail loudly and name the field**, so a
malformed payload surfaces at the parse site instead of as a `NaN` in a chart
or a blank row three screens later.

No code generation, no build step, no dependencies. Pure Dart, so it works in
Flutter apps, server code, CLIs and shared domain packages alike.

```dart
factory Ticker.fromJson(Map<String, dynamic> json) => Ticker(
  symbol: json.asString('symbol'),
  lastPrice: json.asDouble('lastPrice'),      // accepts "64,120.55"
  tradable: json.asBool('tradable'),          // accepts 1, "yes", true
  updatedAt: json.asDateTime('updateTime'),   // accepts epoch ms or ISO 8601
  note: json.asNullableString('note'),        // absent or null -> null
);
```

## Why

`json['lastPrice'] as double` throws a `TypeError` that names neither the field
nor the value, and the moment the server sends `"64120.55"` as a string it
throws at all. The usual retreat is `(json['lastPrice'] as num?)?.toDouble() ?? 0`,
which silently substitutes a zero and pushes the bug into the UI, where it
reads as a rendering fault rather than a parse one.

These casts do neither. Each one takes the field's name alongside its value and
throws a `FormatException` that quotes both:

```
FormatException: Field "lastPrice"="n/a" cannot be parsed as double.
```

That message names the contract that broke, which is usually enough to file the
bug against the right side of it.

## Install

```yaml
dependencies:
  safe_json_cast: ">=1.2.0 <2.0.0"
```

Requires Dart 3.12.0 or newer — Flutter 3.44.0 or newer, if you are on
Flutter. There is no `flutter` constraint in `pubspec.yaml`, so the package
still resolves in server and CLI projects with no Flutter SDK installed.

## The casts

Every cast comes in two forms: a strict one that throws on `null`, and an
`asNullable…` one that maps `null` to `null`.

| Cast          | Accepts                                                                          |
| ------------- | -------------------------------------------------------------------------------- |
| `asString`    | any non-null value; anything but a `String` is rendered with `toString()`         |
| `asStrictString` | a `String` and nothing else — no coercion                                     |
| `asNonEmptyString` | as `asString`, rejecting one that is empty once trimmed                     |
| `asCleanUrl`  | as `asString`, with one leading and one trailing `/` removed                      |
| `asDouble`    | any finite `num`; a decimal `String`, with grouping commas and whitespace stripped |
| `asInt`       | any finite `num`, truncated toward zero; a numeric `String`, likewise             |
| `asBool`      | a `bool`; a `num`, true when non-zero; `true/t/1/yes/y` and `false/f/0/no/n`      |
| `asDateTime`  | a `DateTime`; an ISO 8601 `String`; a `num` epoch, in seconds or milliseconds     |
| `asNum`       | any `num`, subtype intact; a numeric `String`                                     |
| `asBigInt`    | an integral `num`; an integer `String` — a fraction is rejected, not truncated    |
| `asUri`       | a `Uri`; a parseable `String`                                                     |
| `asEnum<T>`   | a `String` matching an enum name case-insensitively, or a `wireNames` key         |
| `asDuration`  | a `Duration`; a `num` or numeric `String`, read in a unit you state               |
| `asMap`       | a `Map` whose keys are all `String`s                                              |
| `asMapOf<T>`  | as `asMap`, with each value converted by a callback                               |
| `asList<T>`   | a `List`, with each element converted by a callback                               |
| `asSet<T>`    | as `asList`, collapsing repeats — or rejecting them                               |

The string forms are the point of the exercise. Exchange and payment APIs send
prices as strings to preserve precision, booleans as `0`/`1`, and timestamps as
epoch integers — often all three in one payload, and not always consistently
between endpoints.

## Two ways to call

The bare functions take the value and its field name:

```dart
asDouble(json['lastPrice'], field: 'lastPrice');
```

The `SafeJsonMap` extension reads off the map and uses the key as the field
name, which removes the second mention:

```dart
json.asDouble('lastPrice');
```

Prefer the extension for whole-object parsing. Reach for the bare functions
when the value did not come from a map — an element inside a list, or a field
whose reported name should differ from its key.

## Lists

`asList` converts each element with a callback that receives an **indexed**
field name, so a failure inside a list says which entry broke:

```dart
json.asList(
  'changeLogs',
  element: (raw, field) => ChangeLog.fromJson(asMap(raw, field: field)),
);
```

Build the child's field name from the one you are given to carry the whole path
into the message:

```dart
json.asList(
  'levels',
  element: (raw, field) =>
      asDouble(asMap(raw, field: field)['price'], field: '$field.price'),
);
// FormatException: Field "levels[1].price"="oops" cannot be parsed as double.
```

`asStringList`, `asIntList`, `asDoubleList` and `asMapList` are shorthands for
the common cases. Lists come back fixed-length; pass `growable: true` when you
need to add to one.

## Enums and dictionaries

`asEnum` matches an enum entry by name, case-insensitively. When the wire
spelling differs from Dart's, map it:

```dart
json.asEnum(
  'status',
  values: OrderStatus.values,
  wireNames: const {'PARTIALLY_FILLED': OrderStatus.partiallyFilled},
);
// FormatException: Field "status"="CANCELED" is not one of [PARTIALLY_FILLED, newOrder, filled, partiallyFilled].
```

`asMapOf` is for the objects an API uses as a dictionary, where the keys are
data and cannot be spelled out in a model. It names the failing entry by key:

```dart
json.asMapOf<double>(
  'balances',
  entry: (raw, field) => asDouble(raw, field: field),
);
// FormatException: Field "balances.BTC"="n/a" cannot be parsed as double.
```

## Handling the failure

Every cast throws a `JsonCastException`, which **is** a `FormatException` — so
catching the latter works as it always did. Catch the former when you want the
parts rather than the sentence:

```dart
try {
  return Ticker.fromJson(json);
} on JsonCastException catch (e) {
  logger.warn('bad ticker', {'field': e.field, 'expected': e.expectedType});
  rethrow;
}
```

When a field genuinely is allowed a default, `tryCast` keeps that decision at
the call site instead of burying it in the cast:

```dart
final fee = tryCast(() => json.asDouble('fee')) ?? 0;
```

## Bounds

`asDouble`, `asInt` and `asNum` take inclusive `min` and `max`, for the values
that convert cleanly but cannot be right:

```dart
json.asDouble('sharePct', min: 0, max: 100);
// FormatException: Field "sharePct"="150" is outside the range 0..100.
```

## Nested fields

`castAt` reaches a leaf through nested objects and arrays, and keeps the whole
path in the failure rather than the leaf's own name:

```dart
json.castAt('data.orders[0].price', asDouble);
// FormatException: Field "data.orders[0].price"="n/a" cannot be parsed as double.
```

Any cast fits, including the `asNullable…` ones. An absent step along the way
resolves to `null`, so the cast decides whether that is an error; a step that
is *present but unwalkable* — indexing into a string — throws, naming the part
of the path that did work. `valueAt` returns the raw value and `hasPath` is the
path-shaped `hasKey`.

Prefer unpacking object by object when you are reading many fields out of the
same node; `castAt` is for the one leaf buried in an envelope.

## Non-finite and out-of-range values

`NaN`, `Infinity` and their string spellings (`'NaN'`, `'1e999'`) parse cleanly
and then slip past every `min` and `max`, so `asDouble`, `asInt` and `asNum`
reject them outright. `asDateTime` and `asDuration` do the same for a number
their result type cannot hold, and every one of these fails as a
`JsonCastException` — never a stray `RangeError` — so `tryCast` and
`on FormatException` catch it. `asInt` reads a string of plain digits as an
integer directly, so a 17-digit id keeps every digit.

## Absent keys

A missing key reads as `null`, so it behaves exactly like an explicit `null` —
the strict casts throw, the nullable ones return `null`. When a
present-but-null field has to be told apart from an absent one, ask first:

```dart
if (json.hasKey('memo')) { /* the server sent the field, possibly as null */ }
```

## Two heuristics worth knowing

**`asDateTime` guesses the epoch unit.** A `num` of 1e12 or more is read as
milliseconds, anything smaller as seconds. That misreads second-precision
timestamps after the year 33658 and millisecond-precision ones before
2001-09-09. When the unit is known, say so and the guess is skipped:

```dart
json.asDateTime('updateTime', unit: EpochUnit.seconds);
```

**`asString` never rejects a non-null value.** A number arriving where a string
was promised becomes `'12'` rather than an error, which is usually what you
want for ids but does mean `asString` will not catch a type drift on its own.
Reach for `asStrictString` where that drift is worth hearing about, or
`asNonEmptyString` where `""` is.

## License

MIT — see [LICENSE](LICENSE).
