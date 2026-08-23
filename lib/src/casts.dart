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
  throw FormatException('Field "$field" is null, expected String.');
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
/// Throws a [FormatException] naming [field] and quoting the value when it
/// cannot be parsed.
double asDouble(Object? value, {required String field}) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value.replaceAll(',', '').trim());
    if (parsed != null) return parsed;
  }
  throw FormatException('Field "$field"="$value" cannot be parsed as double.');
}

/// Casts a raw JSON value to a [double], mapping `null` to `null`.
///
/// See [asDouble].
double? asNullableDouble(Object? value, {required String field}) {
  if (value == null) return null;
  return asDouble(value, field: field);
}

/// Casts a raw JSON value to a non-null [int].
///
/// An [int] passes through. Any other [num] is truncated toward zero. A
/// [String] is parsed as a decimal number — grouping commas and surrounding
/// whitespace are removed — and then truncated, so `'1,024.9'` yields `1024`.
///
/// Throws a [FormatException] naming [field] and quoting the value when it
/// cannot be parsed.
int asInt(Object? value, {required String field}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = double.tryParse(value.replaceAll(',', '').trim());
    if (parsed != null) return parsed.toInt();
  }
  throw FormatException('Field "$field"="$value" cannot be parsed as int.');
}

/// Casts a raw JSON value to an [int], mapping `null` to `null`.
///
/// See [asInt].
int? asNullableInt(Object? value, {required String field}) {
  if (value == null) return null;
  return asInt(value, field: field);
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
  throw FormatException('Field "$field"="$value" cannot be parsed as bool.');
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
/// That threshold is a heuristic. It reads any second-precision timestamp
/// after 33658-09-27 as milliseconds, and any millisecond-precision timestamp
/// before 2001-09-09 as seconds. If your API's unit is known, prefer
/// [asInt] and construct the [DateTime] yourself.
///
/// Throws a [FormatException] naming [field] and quoting the value when it
/// cannot be parsed.
DateTime asDateTime(Object? value, {required String field}) {
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  if (value is num) {
    final epoch = value.toInt();
    if (epoch.abs() >= 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true);
  }
  throw FormatException(
    'Field "$field"="$value" cannot be parsed as DateTime.',
  );
}

/// Casts a raw JSON value to a [DateTime], mapping `null` to `null`.
///
/// See [asDateTime].
DateTime? asNullableDateTime(Object? value, {required String field}) {
  if (value == null) return null;
  return asDateTime(value, field: field);
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
  throw FormatException(
    'Field "$field" is ${value.runtimeType}, expected a JSON object.',
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
/// Throws a [FormatException] naming [field] when [value] is not a list.
List<T> asList<T>(
  Object? value, {
  required String field,
  required T Function(Object? element, String field) element,
}) {
  if (value is! List) {
    throw FormatException(
      'Field "$field" is ${value.runtimeType}, expected a JSON array.',
    );
  }
  return List<T>.generate(
    value.length,
    (int index) => element(value[index], '$field[$index]'),
    growable: false,
  );
}

/// Casts a raw JSON value to a [List], mapping `null` to `null`.
///
/// See [asList].
List<T>? asNullableList<T>(
  Object? value, {
  required String field,
  required T Function(Object? element, String field) element,
}) {
  if (value == null) return null;
  return asList<T>(value, field: field, element: element);
}
