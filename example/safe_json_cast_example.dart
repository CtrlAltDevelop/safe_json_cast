// Parses two payloads with the same model: one well-formed, one with a broken
// field, to show what the failure reads like.
import 'dart:convert';

import 'package:safe_json_cast/safe_json_cast.dart';

class Ticker {
  const Ticker({
    required this.symbol,
    required this.lastPrice,
    required this.priceChangePercent,
    required this.tradable,
    required this.updatedAt,
    required this.tags,
    this.note,
  });

  /// Reads a ticker off a decoded JSON object.
  ///
  /// Note `lastPrice`: the server sends it as a string to keep full precision,
  /// and [SafeJsonMap.asDouble] accepts that without a special case.
  factory Ticker.fromJson(Map<String, dynamic> json) => Ticker(
    symbol: json.asString('symbol'),
    lastPrice: json.asDouble('lastPrice'),
    priceChangePercent: json.asDouble('priceChangePercent'),
    tradable: json.asBool('tradable'),
    updatedAt: json.asDateTime('updateTime'),
    tags: json.asStringList('tags'),
    // Absent from the payload below; a nullable cast returns null rather
    // than throwing.
    note: json.asNullableString('note'),
  );

  final String symbol;
  final double lastPrice;
  final double priceChangePercent;
  final bool tradable;
  final DateTime updatedAt;
  final List<String> tags;
  final String? note;

  @override
  String toString() =>
      'Ticker($symbol, $lastPrice, $priceChangePercent%, '
      'tradable: $tradable, at: $updatedAt, tags: $tags, note: $note)';
}

void main() {
  const good = '''
  {
    "symbol": "BTCUSDT",
    "lastPrice": "64,120.55",
    "priceChangePercent": -1.42,
    "tradable": 1,
    "updateTime": 1766500000000,
    "tags": ["spot", "futures"]
  }
  ''';

  final ticker = Ticker.fromJson(jsonDecode(good) as Map<String, dynamic>);
  print(ticker);

  // The same payload with a price the server failed to fill in. The cast
  // throws where the field is read, naming it, instead of handing a NaN or a
  // zero to the rest of the app.
  const bad = '''
  {
    "symbol": "ETHUSDT",
    "lastPrice": "n/a",
    "priceChangePercent": 0.3,
    "tradable": true,
    "updateTime": "2026-08-23T09:15:00Z",
    "tags": []
  }
  ''';

  try {
    Ticker.fromJson(jsonDecode(bad) as Map<String, dynamic>);
  } on FormatException catch (error) {
    // FormatException: Field "lastPrice"="n/a" cannot be parsed as double.
    print(error);
  }

  // An element cast receives an indexed field name, so building the child
  // field name from it locates the bad entry rather than merely reporting it.
  const nested = '{"levels": [{"price": 1.0}, {"price": "oops"}]}';
  try {
    (jsonDecode(nested) as Map<String, dynamic>).asList(
      'levels',
      element: (Object? raw, String field) =>
          asDouble(asMap(raw, field: field)['price'], field: '$field.price'),
    );
  } on FormatException catch (error) {
    // FormatException: Field "levels[1].price"="oops" cannot be parsed as
    // double.
    print(error);
  }
}
