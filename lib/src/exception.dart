/// The exception every cast in this package throws.
///
/// It extends [FormatException], so existing `on FormatException` handlers
/// keep working and the message reads exactly as it did before. What it adds
/// is the same information in structured form — [field], [value] and
/// [expectedType] — for code that wants to report the failure rather than
/// print it:
///
/// ```dart
/// try {
///   return Ticker.fromJson(json);
/// } on JsonCastException catch (e) {
///   logger.warn('bad payload', {'field': e.field, 'expected': e.expectedType});
///   rethrow;
/// }
/// ```
class JsonCastException extends FormatException {
  /// Creates an exception with an explicit [message].
  ///
  /// Prefer the named constructors below, which render the messages the casts
  /// have always produced.
  JsonCastException({
    required this.field,
    required this.value,
    required this.expectedType,
    required String message,
  }) : super(message);

  /// A field that was `null` where a value was required.
  JsonCastException.nullValue({
    required String field,
    required String expectedType,
  }) : this(
         field: field,
         value: null,
         expectedType: expectedType,
         message: 'Field "$field" is null, expected $expectedType.',
       );

  /// A field whose value is of a shape the cast cannot use at all.
  JsonCastException.wrongType({
    required String field,
    required Object? value,
    required String expectedType,
  }) : this(
         field: field,
         value: value,
         expectedType: expectedType,
         message:
             'Field "$field" is ${value.runtimeType}, expected $expectedType.',
       );

  /// A field of the right shape whose contents could not be converted.
  JsonCastException.unparsable({
    required String field,
    required Object? value,
    required String expectedType,
  }) : this(
         field: field,
         value: value,
         expectedType: expectedType,
         message: 'Field "$field"="$value" cannot be parsed as $expectedType.',
       );

  /// A field that converted cleanly but fell outside the range the caller
  /// allowed.
  JsonCastException.outOfRange({
    required String field,
    required Object? value,
    required String expectedType,
    required String bound,
  }) : this(
         field: field,
         value: value,
         expectedType: expectedType,
         message: 'Field "$field"="$value" is outside $bound.',
       );

  /// The name of the field that failed, including any list index or path the
  /// caller built up — `'trades[3].price'`.
  final String field;

  /// The raw value that failed, as it came out of the decoded JSON.
  final Object? value;

  /// What the cast was trying to produce, as it appears in [message].
  final String expectedType;
}
