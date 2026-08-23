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

  /// Reads [field] as a non-null [double]. See [casts.asDouble].
  double asDouble(String field) => casts.asDouble(this[field], field: field);

  /// Reads [field] as a [double], or `null` when absent or null.
  ///
  /// See [casts.asNullableDouble].
  double? asNullableDouble(String field) =>
      casts.asNullableDouble(this[field], field: field);

  /// Reads [field] as a non-null [int]. See [casts.asInt].
  int asInt(String field) => casts.asInt(this[field], field: field);

  /// Reads [field] as an [int], or `null` when absent or null.
  ///
  /// See [casts.asNullableInt].
  int? asNullableInt(String field) =>
      casts.asNullableInt(this[field], field: field);

  /// Reads [field] as a non-null [bool]. See [casts.asBool].
  bool asBool(String field) => casts.asBool(this[field], field: field);

  /// Reads [field] as a [bool], or `null` when absent or null.
  ///
  /// See [casts.asNullableBool].
  bool? asNullableBool(String field) =>
      casts.asNullableBool(this[field], field: field);

  /// Reads [field] as a non-null [DateTime]. See [casts.asDateTime].
  DateTime asDateTime(String field) =>
      casts.asDateTime(this[field], field: field);

  /// Reads [field] as a [DateTime], or `null` when absent or null.
  ///
  /// See [casts.asNullableDateTime].
  DateTime? asNullableDateTime(String field) =>
      casts.asNullableDateTime(this[field], field: field);

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
  }) => casts.asList<T>(this[field], field: field, element: element);

  /// Reads [field] as a [List], or `null` when absent or null.
  ///
  /// See [casts.asNullableList].
  List<T>? asNullableList<T>(
    String field, {
    required T Function(Object? element, String field) element,
  }) => casts.asNullableList<T>(this[field], field: field, element: element);

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
}
