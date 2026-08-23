# safe_json_cast

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
  safe_json_cast: ^1.0.0
```

Requires Dart 3.13.0 or newer — Flutter 3.47.0 or newer, if you are on Flutter.
There is no `flutter` constraint in `pubspec.yaml`, so the package still
resolves in server and CLI projects with no Flutter SDK installed.

## The casts

Every cast comes in two forms: a strict one that throws on `null`, and an
`asNullable…` one that maps `null` to `null`.

| Cast          | Accepts                                                                          |
| ------------- | -------------------------------------------------------------------------------- |
| `asString`    | any non-null value; anything but a `String` is rendered with `toString()`         |
| `asCleanUrl`  | as `asString`, with one leading and one trailing `/` removed                      |
| `asDouble`    | any `num`; a decimal `String`, with grouping commas and whitespace stripped       |
| `asInt`       | any `num`, truncated toward zero; a numeric `String`, likewise                    |
| `asBool`      | a `bool`; a `num`, true when non-zero; `true/t/1/yes/y` and `false/f/0/no/n`      |
| `asDateTime`  | a `DateTime`; an ISO 8601 `String`; a `num` epoch, in seconds or milliseconds     |
| `asMap`       | a `Map` whose keys are all `String`s                                              |
| `asList<T>`   | a `List`, with each element converted by a callback                               |

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

`asStringList` and `asMapList` are shorthands for the two common cases. Lists
come back fixed-length; copy them if you need to grow one.

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
2001-09-09. When the unit is known, prefer `asInt` and build the `DateTime`
yourself.

**`asString` never rejects a non-null value.** A number arriving where a string
was promised becomes `'12'` rather than an error, which is usually what you
want for ids but does mean `asString` will not catch a type drift on its own.

## License

MIT — see [LICENSE](LICENSE).
