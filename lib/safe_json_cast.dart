/// Typed casts for decoded JSON that name the field they failed on.
///
/// Every cast takes the raw value and the name of the field it came from, and
/// throws a [FormatException] quoting that name when the value cannot be
/// converted. Reach for the [SafeJsonMap] extension to read straight off a
/// decoded map without repeating the field name:
///
/// ```dart
/// Ticker.fromJson(Map<String, dynamic> json) => Ticker(
///   symbol: json.asString('symbol'),
///   lastPrice: json.asDouble('lastPrice'),
///   updatedAt: json.asDateTime('updateTime'),
/// );
/// ```
library safe_json_cast;

export 'src/casts.dart';
export 'src/exception.dart';
export 'src/safe_json_map.dart';
