import 'exception.dart';

/// How a numeric epoch timestamp should be read by [asDateTime].
enum EpochUnit {
  /// Read the number as whole seconds since the Unix epoch.
  seconds,

  /// Read the number as milliseconds since the Unix epoch.
  milliseconds,

  /// Read the number as microseconds since the Unix epoch.
  microseconds,

  /// Pick between [seconds] and [milliseconds] by magnitude: 1e12 and above is
  /// milliseconds, anything smaller is seconds. The default, and a heuristic —
  /// see [asDateTime].
  guess,
}

/// Rejects [converted] when it falls outside an inclusive bound the caller
/// asked for, quoting the [raw] value the field arrived as.
T _checkRange<T extends num>(
  T converted,
  String field,
  Object? raw,
  String expectedType,
  num? min,
  num? max,
) {
  if (min != null && converted < min) {
    throw JsonCastException.outOfRange(
      field: field,
      value: raw,
      expectedType: expectedType,
      bound: max == null ? 'the minimum $min' : 'the range $min..$max',
    );
  }
  if (max != null && converted > max) {
    throw JsonCastException.outOfRange(
      field: field,
      value: raw,
      expectedType: expectedType,
      bound: min == null ? 'the maximum $max' : 'the range $min..$max',
    );
  }
  return converted;
}

/// Casts a raw JSON value to a non-null [String].
///
/// A [String] passes through untouched. Any other non-null value is rendered
/// with `toString()`, so a numeric id arriving as `12` yields `'12'`. Only
/// `null` is rejected.
///
/// Throws a [FormatException] naming [field] when [value] is `null`.
String asString(Object? value, {required String field}) {
  if (value is String) return value;
  if (value != null) return value.toString();
  throw JsonCastException.nullValue(field: field, expectedType: 'String');
}

/// Casts a raw JSON value to a [String], mapping `null` to `null`.
///
/// See [asString] for how non-null values are converted.
String? asNullableString(Object? value, {required String field}) {
  if (value == null) return null;
  return asString(value, field: field);
}

/// Casts a raw JSON value to a [String] with one leading and one trailing
/// `/` removed.
///
/// Intended for URL fragments that a server may or may not send with
/// separators attached, so they can be joined without doubling up:
///
/// ```dart
/// asCleanUrl('/v1/markets/', field: 'markets'); // 'v1/markets'
/// ```
///
/// Only a single separator is stripped from each end. Throws a
/// [FormatException] naming [field] when [value] is `null`.
String asCleanUrl(Object? value, {required String field}) {
  var url = asString(value, field: field);
  if (url.startsWith('/')) url = url.substring(1);
  if (url.endsWith('/')) url = url.substring(0, url.length - 1);
  return url;
}

/// Casts a raw JSON value to a [String] with its outer `/` separators
/// removed, mapping `null` to `null`.
///
/// See [asCleanUrl].
String? asNullableCleanUrl(Object? value, {required String field}) {
  if (value == null) return null;
  return asCleanUrl(value, field: field);
}

/// Casts a raw JSON value to a non-null [double].
///
/// Accepts any [num], and a [String] holding a decimal number — surrounding
/// whitespace and grouping commas are removed first, so `' 1,234.5 '` parses.
/// This is the cast to use for money and quantities, which exchange APIs
/// routinely send as strings to preserve precision.
///
/// Pass [min] or [max] to reject a value that converts cleanly but cannot be
/// right — a negative quantity, a percentage above 100 — at the parse site
/// rather than wherever it is first used. The bounds are inclusive and are
/// checked after conversion.
///
/// Throws a [FormatException] naming [field] and quoting the value when it
/// cannot be parsed.
double asDouble(Object? value, {required String field, num? min, num? max}) {
  if (value is num) {
    return _checkRange(value.toDouble(), field, value, 'double', min, max);
  }
  if (value is String) {
    final parsed = double.tryParse(value.replaceAll(',', '').trim());
    if (parsed != null) {
      return _checkRange(parsed, field, value, 'double', min, max);
    }
  }
  throw JsonCastException.unparsable(
    field: field,
    value: value,
    expectedType: 'double',
  );
}

/// Casts a raw JSON value to a [double], mapping `null` to `null`.
///
/// See [asDouble].
double? asNullableDouble(
  Object? value, {
  required String field,
  num? min,
  num? max,
}) {
  if (value == null) return null;
  return asDouble(value, field: field, min: min, max: max);
}

/// Casts a raw JSON value to a non-null [int].
///
/// An [int] passes through. Any other [num] is truncated toward zero. A
/// [String] is parsed as a decimal number — grouping commas and surrounding
/// whitespace are removed — and then truncated, so `'1,024.9'` yields `1024`.
///
/// Pass [min] or [max] to reject a value that converts cleanly but cannot be
/// right — a negative quantity, a percentage above 100 — at the parse site
/// rather than wherever it is first used. The bounds are inclusive and are
/// checked after conversion.
///
/// Throws a [FormatException] naming [field] and quoting the value when it
/// cannot be parsed.
int asInt(Object? value, {required String field, num? min, num? max}) {
  if (value is int) return _checkRange(value, field, value, 'int', min, max);
  if (value is num) {
    return _checkRange(value.toInt(), field, value, 'int', min, max);
  }
  if (value is String) {
    final parsed = double.tryParse(value.replaceAll(',', '').trim());
    if (parsed != null) {
      return _checkRange(parsed.toInt(), field, value, 'int', min, max);
    }
  }
  throw JsonCastException.unparsable(
    field: field,
    value: value,
    expectedType: 'int',
  );
}

/// Casts a raw JSON value to an [int], mapping `null` to `null`.
///
/// See [asInt].
int? asNullableInt(Object? value, {required String field, num? min, num? max}) {
  if (value == null) return null;
  return asInt(value, field: field, min: min, max: max);
}

/// Casts a raw JSON value to a non-null [bool].
///
/// A [bool] passes through. A [num] is true when non-zero. A [String] is
/// matched case-insensitively against `true`/`t`/`1`/`yes`/`y` and
/// `false`/`f`/`0`/`no`/`n`.
///
/// Throws a [FormatException] naming [field] and quoting the value when it
/// matches none of those.
bool asBool(Object? value, {required String field}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'true':
      case 't':
      case '1':
      case 'yes':
      case 'y':
        return true;
      case 'false':
      case 'f':
      case '0':
      case 'no':
      case 'n':
        return false;
    }
  }
  throw JsonCastException.unparsable(
    field: field,
    value: value,
    expectedType: 'bool',
  );
}

/// Casts a raw JSON value to a [bool], mapping `null` to `null`.
///
/// See [asBool].
bool? asNullableBool(Object? value, {required String field}) {
  if (value == null) return null;
  return asBool(value, field: field);
}

/// Casts a raw JSON value to a non-null [DateTime].
///
/// A [DateTime] passes through. A [String] is read with [DateTime.parse], so
/// ISO 8601 works and the result keeps whatever zone the text specified. A
/// [num] is treated as a Unix epoch offset and always yields a UTC
/// [DateTime]: values of 1e12 and above are read as milliseconds, smaller ones
/// as seconds.
///
/// Pass [unit] to skip the guess when the API's unit is known — that is the
/// safer choice for any timestamp that may fall near the boundary below, and
/// the only way to read microsecond epochs.
///
/// That threshold is a heuristic. It reads any second-precision timestamp
/// after 33658-09-27 as milliseconds, and any millisecond-precision timestamp
/// before 2001-09-09 as seconds. If your API's unit is known, prefer
/// [asInt] and construct the [DateTime] yourself.
///
/// Throws a [FormatException] naming [field] and quoting the value when it
/// cannot be parsed.
DateTime asDateTime(
  Object? value, {
  required String field,
  EpochUnit unit = EpochUnit.guess,
}) {
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  if (value is num) {
    final epoch = value.toInt();
    switch (unit) {
      case EpochUnit.seconds:
        return DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true);
      case EpochUnit.milliseconds:
        return DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true);
      case EpochUnit.microseconds:
        return DateTime.fromMicrosecondsSinceEpoch(epoch, isUtc: true);
      case EpochUnit.guess:
        if (epoch.abs() >= 1000000000000) {
          return DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true);
        }
        return DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true);
    }
  }
  throw JsonCastException.unparsable(
    field: field,
    value: value,
    expectedType: 'DateTime',
  );
}

/// Casts a raw JSON value to a [DateTime], mapping `null` to `null`.
///
/// See [asDateTime].
DateTime? asNullableDateTime(
  Object? value, {
  required String field,
  EpochUnit unit = EpochUnit.guess,
}) {
  if (value == null) return null;
  return asDateTime(value, field: field, unit: unit);
}

/// Casts a raw JSON value to a non-null JSON object.
///
/// Use it to hand a nested object to another `fromJson` without an unchecked
/// `as Map<String, dynamic>`, which would otherwise fail far from the field
/// that caused it.
///
/// Throws a [FormatException] naming [field] when [value] is not a map keyed
/// by [String].
Map<String, dynamic> asMap(Object? value, {required String field}) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    // A map decoded from a non-JSON source, or one that lost its type
    // argument, still qualifies as long as every key is a String.
    if (value.keys.every((Object? key) => key is String)) {
      return value.cast<String, dynamic>();
    }
  }
  throw JsonCastException.wrongType(
    field: field,
    value: value,
    expectedType: 'a JSON object',
  );
}

/// Casts a raw JSON value to a JSON object, mapping `null` to `null`.
///
/// See [asMap].
Map<String, dynamic>? asNullableMap(Object? value, {required String field}) {
  if (value == null) return null;
  return asMap(value, field: field);
}

/// Casts a raw JSON value to a non-null [List], converting each element with
/// [element].
///
/// [element] receives the raw element and an indexed field name — `'trades[3]'`
/// for the fourth entry of `trades` — so a cast failure inside the list still
/// says which entry broke:
///
/// ```dart
/// asList(
///   json['changeLogs'],
///   field: 'changeLogs',
///   element: (raw, field) => ChangeLog.fromJson(asMap(raw, field: field)),
/// );
/// ```
///
/// The result is fixed-length unless [growable] is set.
///
/// Throws a [FormatException] naming [field] when [value] is not a list.
List<T> asList<T>(
  Object? value, {
  required String field,
  required T Function(Object? element, String field) element,
  bool growable = false,
}) {
  if (value is! List) {
    throw JsonCastException.wrongType(
      field: field,
      value: value,
      expectedType: 'a JSON array',
    );
  }
  return List<T>.generate(
    value.length,
    (int index) => element(value[index], '$field[$index]'),
    growable: growable,
  );
}

/// Casts a raw JSON value to a [List], mapping `null` to `null`.
///
/// See [asList].
List<T>? asNullableList<T>(
  Object? value, {
  required String field,
  required T Function(Object? element, String field) element,
  bool growable = false,
}) {
  if (value == null) return null;
  return asList<T>(value, field: field, element: element, growable: growable);
}

/// Casts a raw JSON value to a non-null [num].
///
/// A [num] passes through with its own subtype intact — an `int` stays an
/// `int` — and a numeric [String] is parsed, grouping commas and surrounding
/// whitespace removed first. Use it when a field is genuinely either, and
/// rounding it through [asDouble] or [asInt] would lose something.
///
/// Throws a [JsonCastException] naming [field] and quoting the value when it
/// cannot be parsed.
num asNum(Object? value, {required String field, num? min, num? max}) {
  if (value is num) return _checkRange(value, field, value, 'num', min, max);
  if (value is String) {
    final parsed = num.tryParse(value.replaceAll(',', '').trim());
    if (parsed != null) {
      return _checkRange(parsed, field, value, 'num', min, max);
    }
  }
  throw JsonCastException.unparsable(
    field: field,
    value: value,
    expectedType: 'num',
  );
}

/// Casts a raw JSON value to a [num], mapping `null` to `null`.
///
/// See [asNum].
num? asNullableNum(Object? value, {required String field, num? min, num? max}) {
  if (value == null) return null;
  return asNum(value, field: field, min: min, max: max);
}

/// Casts a raw JSON value to a non-null [BigInt].
///
/// An integral [num] and an integer [String] both convert — grouping commas
/// and surrounding whitespace are removed. This is the cast for identifiers
/// and balances that overflow a Dart [int] on the web, where `int` is a
/// double: a 19-digit order id survives here and does not there.
///
/// A non-integral value is rejected rather than truncated, since silently
/// dropping a fraction from a quantity is the kind of loss this package
/// exists to make loud.
///
/// Throws a [JsonCastException] naming [field] and quoting the value when it
/// cannot be parsed.
BigInt asBigInt(Object? value, {required String field}) {
  if (value is BigInt) return value;
  if (value is int) return BigInt.from(value);
  if (value is num && value == value.roundToDouble() && value.isFinite) {
    return BigInt.from(value);
  }
  if (value is String) {
    final parsed = BigInt.tryParse(value.replaceAll(',', '').trim());
    if (parsed != null) return parsed;
  }
  throw JsonCastException.unparsable(
    field: field,
    value: value,
    expectedType: 'BigInt',
  );
}

/// Casts a raw JSON value to a [BigInt], mapping `null` to `null`.
///
/// See [asBigInt].
BigInt? asNullableBigInt(Object? value, {required String field}) {
  if (value == null) return null;
  return asBigInt(value, field: field);
}

/// Casts a raw JSON value to a non-null [Uri].
///
/// A [Uri] passes through. A [String] is read with [Uri.tryParse] after
/// trimming, so the malformed ones fail here rather than at the request that
/// would have used them.
///
/// Throws a [JsonCastException] naming [field] and quoting the value when it
/// cannot be parsed.
Uri asUri(Object? value, {required String field}) {
  if (value is Uri) return value;
  if (value is String) {
    final parsed = Uri.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  throw JsonCastException.unparsable(
    field: field,
    value: value,
    expectedType: 'Uri',
  );
}

/// Casts a raw JSON value to a [Uri], mapping `null` to `null`.
///
/// See [asUri].
Uri? asNullableUri(Object? value, {required String field}) {
  if (value == null) return null;
  return asUri(value, field: field);
}

/// Casts a raw JSON value to one of the enum [values], matching by name.
///
/// The value is read as a [String] and compared against `EnumName.name`,
/// case-insensitively and ignoring surrounding whitespace, so `'FILLED'`,
/// `'filled'` and `'Filled'` all reach `OrderStatus.filled`. Pass [wireNames]
/// when the API's spelling differs from Dart's — a map from the wire value to
/// the enum entry, consulted first and matched case-insensitively too:
///
/// ```dart
/// asEnum(
///   json['status'],
///   field: 'status',
///   values: OrderStatus.values,
///   wireNames: const {'PARTIALLY_FILLED': OrderStatus.partiallyFilled},
/// );
/// ```
///
/// Throws a [JsonCastException] naming [field], quoting the value and listing
/// the accepted names when nothing matches.
T asEnum<T extends Enum>(
  Object? value, {
  required String field,
  required List<T> values,
  Map<String, T> wireNames = const {},
}) {
  if (value is T) return value;
  final name = asString(value, field: field).trim().toLowerCase();
  for (final MapEntry<String, T> entry in wireNames.entries) {
    if (entry.key.toLowerCase() == name) return entry.value;
  }
  for (final T candidate in values) {
    if (candidate.name.toLowerCase() == name) return candidate;
  }
  final String accepted = <String>[
    ...wireNames.keys,
    ...values.map((T candidate) => candidate.name),
  ].join(', ');
  throw JsonCastException(
    field: field,
    value: value,
    expectedType: 'one of [$accepted]',
    message: 'Field "$field"="$value" is not one of [$accepted].',
  );
}

/// Casts a raw JSON value to one of the enum [values], mapping `null` to
/// `null`.
///
/// See [asEnum].
T? asNullableEnum<T extends Enum>(
  Object? value, {
  required String field,
  required List<T> values,
  Map<String, T> wireNames = const {},
}) {
  if (value == null) return null;
  return asEnum<T>(value, field: field, values: values, wireNames: wireNames);
}

/// Casts a raw JSON value to a non-null map with [String] keys, converting
/// each entry's value with [entry].
///
/// For the objects an API uses as a dictionary rather than a record — a
/// balance per asset, a label per locale — where the keys are data and cannot
/// be spelled out in a model. [entry] receives the raw value and a keyed
/// field name — `'balances.BTC'` — so a failure inside still says which entry
/// broke.
///
/// ```dart
/// asMapOf<double>(
///   json['balances'],
///   field: 'balances',
///   entry: (raw, field) => asDouble(raw, field: field),
/// );
/// ```
///
/// Throws a [JsonCastException] naming [field] when [value] is not a JSON
/// object.
Map<String, T> asMapOf<T>(
  Object? value, {
  required String field,
  required T Function(Object? value, String field) entry,
}) {
  final Map<String, dynamic> raw = asMap(value, field: field);
  return <String, T>{
    for (final MapEntry<String, dynamic> e in raw.entries)
      e.key: entry(e.value, '$field.${e.key}'),
  };
}

/// Casts a raw JSON value to a map with [String] keys, mapping `null` to
/// `null`.
///
/// See [asMapOf].
Map<String, T>? asNullableMapOf<T>(
  Object? value, {
  required String field,
  required T Function(Object? value, String field) entry,
}) {
  if (value == null) return null;
  return asMapOf<T>(value, field: field, entry: entry);
}

/// Runs [cast] and returns `null` instead of throwing when it fails.
///
/// The escape hatch for the field that really is allowed a default. Keeping
/// the fallback at the call site leaves it visible, unlike a cast that
/// swallows the failure internally:
///
/// ```dart
/// final double fee = tryCast(() => json.asDouble('fee')) ?? 0;
/// ```
///
/// Only a [FormatException] — which every cast here throws — is caught.
/// Anything else propagates.
T? tryCast<T>(T Function() cast) {
  try {
    return cast();
  } on FormatException {
    return null;
  }
}

/// How a numeric value should be read by [asDuration].
enum DurationUnit {
  /// Read the number as whole seconds.
  seconds,

  /// Read the number as milliseconds.
  milliseconds,

  /// Read the number as microseconds.
  microseconds,

  /// Read the number as whole minutes.
  minutes,
}

/// Casts a raw JSON value to a non-null [String], rejecting anything that is
/// not already one.
///
/// The strict counterpart to [asString], which renders any non-null value with
/// `toString()` and so cannot catch a type drift on its own. Use this one where
/// a number arriving in place of a string is a bug worth hearing about rather
/// than something to paper over.
///
/// Throws a [JsonCastException] naming [field] when [value] is not a [String].
String asStrictString(Object? value, {required String field}) {
  if (value is String) return value;
  throw JsonCastException.wrongType(
    field: field,
    value: value,
    expectedType: 'String',
  );
}

/// Casts a raw JSON value to a [String] without coercion, mapping `null` to
/// `null`.
///
/// See [asStrictString].
String? asNullableStrictString(Object? value, {required String field}) {
  if (value == null) return null;
  return asStrictString(value, field: field);
}

/// Casts a raw JSON value to a [String] that is not empty once trimmed.
///
/// An API that sends `""` for a missing id is claiming to have sent one, and
/// the empty string then travels as far as any other bad value would. This
/// rejects it where it arrives. The returned string is the original, trimmed
/// only if [trim] is set.
///
/// See [asString] for how non-null values are converted.
///
/// Throws a [JsonCastException] naming [field] when the value is `null`, or is
/// empty or whitespace-only.
String asNonEmptyString(
  Object? value, {
  required String field,
  bool trim = false,
}) {
  final String text = asString(value, field: field);
  if (text.trim().isEmpty) {
    throw JsonCastException(
      field: field,
      value: value,
      expectedType: 'a non-empty String',
      message: 'Field "$field" is empty, expected a non-empty String.',
    );
  }
  return trim ? text.trim() : text;
}

/// Casts a raw JSON value to a non-empty [String], mapping `null` to `null`.
///
/// An empty string is still rejected rather than folded into `null`, since the
/// two say different things about the payload. Reach for
/// `tryCast(() => asNonEmptyString(...))` when you would rather have the
/// `null`.
///
/// See [asNonEmptyString].
String? asNullableNonEmptyString(
  Object? value, {
  required String field,
  bool trim = false,
}) {
  if (value == null) return null;
  return asNonEmptyString(value, field: field, trim: trim);
}

/// Casts a raw JSON value to a non-null [Duration].
///
/// A [Duration] passes through. A [num] is read in [unit], which defaults to
/// seconds — the unit an API means by `expiresIn` or `ttl` — and a numeric
/// [String] is parsed the same way, so `"3600"` and `3600` agree. Fractional
/// values are kept to microsecond precision, so `1.5` seconds is 1500ms.
///
/// There is no guess here of the kind [asDateTime] makes: a duration carries
/// no magnitude that would give its unit away, so the caller states it.
///
/// Throws a [JsonCastException] naming [field] and quoting the value when it
/// cannot be parsed.
Duration asDuration(
  Object? value, {
  required String field,
  DurationUnit unit = DurationUnit.seconds,
}) {
  if (value is Duration) return value;
  final num? amount = value is num
      ? value
      : value is String
      ? num.tryParse(value.replaceAll(',', '').trim())
      : null;
  if (amount != null) {
    final double micros;
    switch (unit) {
      case DurationUnit.microseconds:
        micros = amount.toDouble();
        break;
      case DurationUnit.milliseconds:
        micros = amount * 1000;
        break;
      case DurationUnit.seconds:
        micros = amount * 1000000;
        break;
      case DurationUnit.minutes:
        micros = amount * 60000000;
        break;
    }
    return Duration(microseconds: micros.round());
  }
  throw JsonCastException.unparsable(
    field: field,
    value: value,
    expectedType: 'Duration',
  );
}

/// Casts a raw JSON value to a [Duration], mapping `null` to `null`.
///
/// See [asDuration].
Duration? asNullableDuration(
  Object? value, {
  required String field,
  DurationUnit unit = DurationUnit.seconds,
}) {
  if (value == null) return null;
  return asDuration(value, field: field, unit: unit);
}

/// Casts a raw JSON value to a non-null [Set], converting each element with
/// [element].
///
/// For the arrays an API uses as a set — permissions, enabled features, tags —
/// where membership is the only question ever asked of them. Element order is
/// preserved, since the result is a [LinkedHashSet].
///
/// A repeated element collapses silently by default, which is usually what the
/// payload meant. Set [allowDuplicates] to `false` to treat one as the
/// contradiction it is and throw instead, naming the entry that repeated.
///
/// Throws a [JsonCastException] naming [field] when [value] is not a list.
Set<T> asSet<T>(
  Object? value, {
  required String field,
  required T Function(Object? element, String field) element,
  bool allowDuplicates = true,
}) {
  final List<T> elements = asList<T>(value, field: field, element: element);
  final Set<T> unique = <T>{};
  for (int index = 0; index < elements.length; index++) {
    if (!unique.add(elements[index]) && !allowDuplicates) {
      throw JsonCastException(
        field: '$field[$index]',
        value: elements[index],
        expectedType: 'a unique entry',
        message:
            'Field "$field[$index]"="${elements[index]}" repeats an earlier '
            'entry.',
      );
    }
  }
  return unique;
}

/// Casts a raw JSON value to a [Set], mapping `null` to `null`.
///
/// See [asSet].
Set<T>? asNullableSet<T>(
  Object? value, {
  required String field,
  required T Function(Object? element, String field) element,
  bool allowDuplicates = true,
}) {
  if (value == null) return null;
  return asSet<T>(
    value,
    field: field,
    element: element,
    allowDuplicates: allowDuplicates,
  );
}

/// Walks [path] through nested JSON [root] and returns the raw value it lands
/// on.
///
/// [path] is dot-separated, with bracketed indices for arrays:
/// `'data.orders[0].price'`. A segment that is absent — a key the object does
/// not have, an index past the end of an array — resolves to `null`, exactly
/// as a missing key does everywhere else in this package, so the cast applied
/// afterwards decides whether that is an error.
///
/// A segment that is *present but unwalkable* is a different matter: reading
/// `'user.name'` when `user` is a string means the payload is not shaped the
/// way the caller thinks, and that throws a [JsonCastException] naming the
/// part of the path that was consumed before the shape gave out.
///
/// Prefer [SafeJsonMap.castAt], which pairs this with a cast and reports the
/// whole path as the field name.
Object? valueAtPath(Object? root, String path) => _walkPath(root, path).value;

/// What [_walkPath] found: the value a path landed on, and whether its final
/// step was there at all.
class _PathResult {
  const _PathResult(this.value, this.present);

  final Object? value;
  final bool present;
}

/// Whether [path] resolves to anything in nested JSON [root], whatever its
/// value.
///
/// Tells a path that is absent from one that is present and explicitly `null`,
/// the way [SafeJsonMap.hasKey] does for a single key. Throws for the same
/// unwalkable middle as [valueAtPath].
bool pathExists(Object? root, String path) => _walkPath(root, path).present;

/// Walks [path] through [root], reporting both the value and whether the final
/// step was actually there.
_PathResult _walkPath(Object? root, String path) {
  Object? current = root;
  bool present = true;
  final StringBuffer walked = StringBuffer();

  for (final String segment in _pathSegments(path)) {
    final bool isIndex = segment.startsWith('[');
    final String consumed = walked.isEmpty
        ? segment
        : isIndex
        ? '$walked$segment'
        : '$walked.$segment';

    if (!present || (current == null && walked.isNotEmpty)) {
      return const _PathResult(null, false);
    }

    if (isIndex) {
      final int? index = int.tryParse(segment.substring(1, segment.length - 1));
      if (index == null) {
        throw JsonCastException(
          field: consumed,
          value: segment,
          expectedType: 'an array index',
          message: 'Path segment "$segment" of "$path" is not an array index.',
        );
      }
      if (current is! List) {
        throw JsonCastException.wrongType(
          field: walked.toString(),
          value: current,
          expectedType: 'a JSON array',
        );
      }
      present = index >= 0 && index < current.length;
      current = present ? current[index] : null;
    } else {
      if (current is! Map) {
        throw JsonCastException.wrongType(
          field: walked.toString(),
          value: current,
          expectedType: 'a JSON object',
        );
      }
      present = current.containsKey(segment);
      current = current[segment];
    }
    walked
      ..clear()
      ..write(consumed);
  }
  return _PathResult(current, present);
}

/// Splits `'data.orders[0].price'` into `data`, `orders`, `[0]`, `price`.
Iterable<String> _pathSegments(String path) sync* {
  for (final String part in path.split('.')) {
    final int bracket = part.indexOf('[');
    if (bracket == -1) {
      yield part;
      continue;
    }
    if (bracket > 0) yield part.substring(0, bracket);
    final RegExp index = RegExp(r'\[[^\]]*\]');
    for (final RegExpMatch match in index.allMatches(part, bracket)) {
      yield match.group(0)!;
    }
  }
}
