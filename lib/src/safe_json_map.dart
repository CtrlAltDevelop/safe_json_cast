import 'casts.dart' as casts;

/// Reads typed values straight off a decoded JSON object.
///
/// Each method looks the key up and applies the matching cast from
/// `casts.dart`, passing the key as the field name. That removes the
/// double mention of every field that the bare casts require:
///
/// ```dart
/// // With the bare cast:
/// asDouble(json['lastPrice'], field: 'lastPrice');
/// // With this extension:
/// json.asDouble('lastPrice');
/// ```
///
/// A missing key reads as `null`, so it behaves exactly like an explicit
/// `null`: the non-nullable methods throw and the `asNullable*` ones return
/// `null`. Use [hasKey] when a present-but-null field has to be told apart
/// from an absent one.
extension SafeJsonMap on Map<String, dynamic> {
  /// Whether [field] is present, whatever its value.
  ///
  /// Distinguishes `{'memo': null}` from `{}`, which the casts below treat
  /// alike.
  bool hasKey(String field) => containsKey(field);

  /// Reads [field] as a non-null [String]. See [casts.asString].
  String asString(String field) => casts.asString(this[field], field: field);

  /// Reads [field] as a [String], or `null` when absent or null.
  ///
  /// See [casts.asNullableString].
  String? asNullableString(String field) =>
      casts.asNullableString(this[field], field: field);

  /// Reads [field] as a [String] with its outer `/` separators removed.
  ///
  /// See [casts.asCleanUrl].
  String asCleanUrl(String field) =>
      casts.asCleanUrl(this[field], field: field);

  /// Reads [field] as a cleaned URL fragment, or `null` when absent or null.
  ///
  /// See [casts.asNullableCleanUrl].
  String? asNullableCleanUrl(String field) =>
      casts.asNullableCleanUrl(this[field], field: field);

  /// Reads [field] as a non-null [double].
  ///
  /// Pass [min] or [max] to reject a value outside an inclusive bound. See
  /// [casts.asDouble].
  double asDouble(String field, {num? min, num? max}) =>
      casts.asDouble(this[field], field: field, min: min, max: max);

  /// Reads [field] as a [double], or `null` when absent or null.
  ///
  /// See [casts.asNullableDouble].
  double? asNullableDouble(String field, {num? min, num? max}) =>
      casts.asNullableDouble(this[field], field: field, min: min, max: max);

  /// Reads [field] as a non-null [int].
  ///
  /// Pass [min] or [max] to reject a value outside an inclusive bound. See
  /// [casts.asInt].
  int asInt(String field, {num? min, num? max}) =>
      casts.asInt(this[field], field: field, min: min, max: max);

  /// Reads [field] as an [int], or `null` when absent or null.
  ///
  /// See [casts.asNullableInt].
  int? asNullableInt(String field, {num? min, num? max}) =>
      casts.asNullableInt(this[field], field: field, min: min, max: max);

  /// Reads [field] as a non-null [bool]. See [casts.asBool].
  bool asBool(String field) => casts.asBool(this[field], field: field);

  /// Reads [field] as a [bool], or `null` when absent or null.
  ///
  /// See [casts.asNullableBool].
  bool? asNullableBool(String field) =>
      casts.asNullableBool(this[field], field: field);

  /// Reads [field] as a non-null [DateTime].
  ///
  /// Pass [unit] to read a numeric epoch in a known unit rather than the
  /// magnitude guess. See [casts.asDateTime].
  DateTime asDateTime(
    String field, {
    casts.EpochUnit unit = casts.EpochUnit.guess,
  }) => casts.asDateTime(this[field], field: field, unit: unit);

  /// Reads [field] as a [DateTime], or `null` when absent or null.
  ///
  /// See [casts.asNullableDateTime].
  DateTime? asNullableDateTime(
    String field, {
    casts.EpochUnit unit = casts.EpochUnit.guess,
  }) => casts.asNullableDateTime(this[field], field: field, unit: unit);

  /// Reads [field] as a non-null nested JSON object. See [casts.asMap].
  Map<String, dynamic> asMap(String field) =>
      casts.asMap(this[field], field: field);

  /// Reads [field] as a nested JSON object, or `null` when absent or null.
  ///
  /// See [casts.asNullableMap].
  Map<String, dynamic>? asNullableMap(String field) =>
      casts.asNullableMap(this[field], field: field);

  /// Reads [field] as a non-null [List], converting each element with
  /// [element].
  ///
  /// ```dart
  /// json.asList(
  ///   'changeLogs',
  ///   element: (raw, field) => ChangeLog.fromJson(asMap(raw, field: field)),
  /// );
  /// ```
  ///
  /// See [casts.asList].
  List<T> asList<T>(
    String field, {
    required T Function(Object? element, String field) element,
    bool growable = false,
  }) => casts.asList<T>(
    this[field],
    field: field,
    element: element,
    growable: growable,
  );

  /// Reads [field] as a [List], or `null` when absent or null.
  ///
  /// See [casts.asNullableList].
  List<T>? asNullableList<T>(
    String field, {
    required T Function(Object? element, String field) element,
    bool growable = false,
  }) => casts.asNullableList<T>(
    this[field],
    field: field,
    element: element,
    growable: growable,
  );

  /// Reads [field] as a non-null list of nested JSON objects.
  ///
  /// A shorthand for [asList] with an [casts.asMap] element cast, for the
  /// common case of handing each entry to another `fromJson`:
  ///
  /// ```dart
  /// json.asMapList('changeLogs').map(ChangeLog.fromJson).toList();
  /// ```
  List<Map<String, dynamic>> asMapList(String field) => asList(
    field,
    element: (Object? raw, String elementField) =>
        casts.asMap(raw, field: elementField),
  );

  /// Reads [field] as a non-null list of [String]s.
  ///
  /// A shorthand for [asList] with an [casts.asString] element cast.
  List<String> asStringList(String field) => asList(
    field,
    element: (Object? raw, String elementField) =>
        casts.asString(raw, field: elementField),
  );

  /// Reads [field] as a non-null [num].
  ///
  /// Pass [min] or [max] to reject a value outside an inclusive bound. See
  /// [casts.asNum].
  num asNum(String field, {num? min, num? max}) =>
      casts.asNum(this[field], field: field, min: min, max: max);

  /// Reads [field] as a [num], or `null` when absent or null.
  ///
  /// See [casts.asNullableNum].
  num? asNullableNum(String field, {num? min, num? max}) =>
      casts.asNullableNum(this[field], field: field, min: min, max: max);

  /// Reads [field] as a non-null [BigInt]. See [casts.asBigInt].
  BigInt asBigInt(String field) => casts.asBigInt(this[field], field: field);

  /// Reads [field] as a [BigInt], or `null` when absent or null.
  ///
  /// See [casts.asNullableBigInt].
  BigInt? asNullableBigInt(String field) =>
      casts.asNullableBigInt(this[field], field: field);

  /// Reads [field] as a non-null [Uri]. See [casts.asUri].
  Uri asUri(String field) => casts.asUri(this[field], field: field);

  /// Reads [field] as a [Uri], or `null` when absent or null.
  ///
  /// See [casts.asNullableUri].
  Uri? asNullableUri(String field) =>
      casts.asNullableUri(this[field], field: field);

  /// Reads [field] as one of the enum [values], matching by name.
  ///
  /// See [casts.asEnum].
  T asEnum<T extends Enum>(
    String field, {
    required List<T> values,
    Map<String, T> wireNames = const <String, Never>{},
  }) => casts.asEnum<T>(
    this[field],
    field: field,
    values: values,
    wireNames: wireNames,
  );

  /// Reads [field] as one of the enum [values], or `null` when absent or null.
  ///
  /// See [casts.asNullableEnum].
  T? asNullableEnum<T extends Enum>(
    String field, {
    required List<T> values,
    Map<String, T> wireNames = const <String, Never>{},
  }) => casts.asNullableEnum<T>(
    this[field],
    field: field,
    values: values,
    wireNames: wireNames,
  );

  /// Reads [field] as a non-null map keyed by [String], converting each
  /// entry's value with [entry].
  ///
  /// See [casts.asMapOf].
  Map<String, T> asMapOf<T>(
    String field, {
    required T Function(Object? value, String field) entry,
  }) => casts.asMapOf<T>(this[field], field: field, entry: entry);

  /// Reads [field] as a map keyed by [String], or `null` when absent or null.
  ///
  /// See [casts.asNullableMapOf].
  Map<String, T>? asNullableMapOf<T>(
    String field, {
    required T Function(Object? value, String field) entry,
  }) => casts.asNullableMapOf<T>(this[field], field: field, entry: entry);

  /// Reads [field] as a non-null list of [int]s.
  ///
  /// A shorthand for [asList] with an [casts.asInt] element cast.
  List<int> asIntList(String field) => asList(
    field,
    element: (Object? raw, String elementField) =>
        casts.asInt(raw, field: elementField),
  );

  /// Reads [field] as a non-null list of [double]s.
  ///
  /// A shorthand for [asList] with an [casts.asDouble] element cast.
  List<double> asDoubleList(String field) => asList(
    field,
    element: (Object? raw, String elementField) =>
        casts.asDouble(raw, field: elementField),
  );

  /// Reads [field] as a non-null [String], rejecting a non-[String].
  ///
  /// See [casts.asStrictString].
  String asStrictString(String field) =>
      casts.asStrictString(this[field], field: field);

  /// Reads [field] as a [String] without coercion, or `null` when absent or
  /// null.
  ///
  /// See [casts.asNullableStrictString].
  String? asNullableStrictString(String field) =>
      casts.asNullableStrictString(this[field], field: field);

  /// Reads [field] as a [String] that is not empty once trimmed.
  ///
  /// See [casts.asNonEmptyString].
  String asNonEmptyString(String field, {bool trim = false}) =>
      casts.asNonEmptyString(this[field], field: field, trim: trim);

  /// Reads [field] as a non-empty [String], or `null` when absent or null.
  ///
  /// See [casts.asNullableNonEmptyString].
  String? asNullableNonEmptyString(String field, {bool trim = false}) =>
      casts.asNullableNonEmptyString(this[field], field: field, trim: trim);

  /// Reads [field] as a non-null [Duration], reading a number in [unit].
  ///
  /// See [casts.asDuration].
  Duration asDuration(
    String field, {
    casts.DurationUnit unit = casts.DurationUnit.seconds,
  }) => casts.asDuration(this[field], field: field, unit: unit);

  /// Reads [field] as a [Duration], or `null` when absent or null.
  ///
  /// See [casts.asNullableDuration].
  Duration? asNullableDuration(
    String field, {
    casts.DurationUnit unit = casts.DurationUnit.seconds,
  }) => casts.asNullableDuration(this[field], field: field, unit: unit);

  /// Reads [field] as a non-null [Set], converting each element with
  /// [element].
  ///
  /// See [casts.asSet].
  Set<T> asSet<T>(
    String field, {
    required T Function(Object? element, String field) element,
    bool allowDuplicates = true,
  }) => casts.asSet<T>(
    this[field],
    field: field,
    element: element,
    allowDuplicates: allowDuplicates,
  );

  /// Reads [field] as a [Set], or `null` when absent or null.
  ///
  /// See [casts.asNullableSet].
  Set<T>? asNullableSet<T>(
    String field, {
    required T Function(Object? element, String field) element,
    bool allowDuplicates = true,
  }) => casts.asNullableSet<T>(
    this[field],
    field: field,
    element: element,
    allowDuplicates: allowDuplicates,
  );

  /// Reads [field] as a non-null [Set] of [String]s.
  ///
  /// A shorthand for [asSet] with an [casts.asString] element cast.
  Set<String> asStringSet(String field, {bool allowDuplicates = true}) => asSet(
    field,
    element: (Object? raw, String elementField) =>
        casts.asString(raw, field: elementField),
    allowDuplicates: allowDuplicates,
  );

  /// Whether [path] resolves to anything, walking nested objects and arrays.
  ///
  /// Answers for a path what [hasKey] answers for a key: `true` when the path
  /// is present, whatever its value, including an explicit `null`.
  ///
  /// See [casts.valueAtPath] for the path syntax.
  bool hasPath(String path) => casts.pathExists(this, path);

  /// Reads the raw value [path] lands on, walking nested objects and arrays.
  ///
  /// `null` when any step of the path is absent. See [casts.valueAtPath] for
  /// the syntax and for what happens when a step is present but not walkable.
  Object? valueAt(String path) => casts.valueAtPath(this, path);

  /// Reads a nested value with [cast], reporting the whole [path] as the field
  /// name.
  ///
  /// Saves unpacking a nested payload one object at a time when only one leaf
  /// is wanted, and keeps the path in the failure rather than the leaf's own
  /// name:
  ///
  /// ```dart
  /// json.castAt('data.orders[0].price', casts.asDouble);
  /// // FormatException: Field "data.orders[0].price"="n/a" cannot be parsed
  /// // as double.
  /// ```
  ///
  /// Any cast in this package fits [cast] directly, and so does an
  /// `asNullable…` one when the leaf is optional.
  T castAt<T>(
    String path,
    T Function(Object? value, {required String field}) cast,
  ) => cast(casts.valueAtPath(this, path), field: path);
}
