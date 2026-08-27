// Parses two payloads with the same model: one well-formed, one with a broken
// field, to show what the failure reads like.
import 'dart:convert';

import 'package:safe_json_cast/safe_json_cast.dart';

/// The status an order arrives with. The wire spells two of these
/// differently, which [SafeJsonMap.asEnum] takes a map for.
enum OrderStatus { open, filled, partiallyFilled }

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
  } on JsonCastException catch (error) {
    // FormatException: Field "lastPrice"="n/a" cannot be parsed as double.
    print(error);
    // The same failure as data, for a log line or an error report.
    print('field=${error.field} expected=${error.expectedType}');
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

  // Enums come off the wire in whatever case the API prefers, and sometimes
  // under a different name entirely.
  const order = '{"status": "PARTIALLY_FILLED", "fee": "n/a"}';
  final Map<String, dynamic> orderJson =
      jsonDecode(order) as Map<String, dynamic>;
  print(
    orderJson.asEnum(
      'status',
      values: OrderStatus.values,
      wireNames: const <String, OrderStatus>{
        'PARTIALLY_FILLED': OrderStatus.partiallyFilled,
      },
    ),
  );

  // A field that really is allowed a default: tryCast keeps the fallback at
  // the call site, where it can be read, rather than inside the cast.
  print(tryCast(() => orderJson.asDouble('fee')) ?? 0);

  // A leaf buried in an envelope: castAt walks to it and keeps the whole path
  // in the failure, instead of reporting the leaf's own name.
  const envelope = '''
  {
    "data": { "orders": [ { "price": "1.5" }, { "price": "n/a" } ] },
    "meta": { "expiresIn": 3600 }
  }
  ''';
  final Map<String, dynamic> envelopeJson =
      jsonDecode(envelope) as Map<String, dynamic>;
  print(envelopeJson.castAt('data.orders[0].price', asDouble));
  try {
    envelopeJson.castAt('data.orders[1].price', asDouble);
  } on JsonCastException catch (error) {
    // FormatException: Field "data.orders[1].price"="n/a" cannot be parsed as
    // double.
    print(error);
  }

  // A number an API means as seconds, which Duration should not have to be
  // reconstructed from by hand at every call site.
  print(envelopeJson.castAt('meta.expiresIn', asDuration));

  // A bound catches the value that converts cleanly but cannot be right.
  try {
    (<String, dynamic>{'sharePct': 150}).asDouble('sharePct', min: 0, max: 100);
  } on JsonCastException catch (error) {
    // FormatException: Field "sharePct"="150" is outside the range 0..100.
    print(error);
  }

  // An object the API uses as a dictionary: the keys are data, so they cannot
  // be spelled out in a model. A bad entry is named by key.
  const wallet = '{"balances": {"BTC": "0.5", "ETH": 2}}';
  print(
    (jsonDecode(wallet) as Map<String, dynamic>).asMapOf<double>(
      'balances',
      entry: (Object? raw, String field) => asDouble(raw, field: field),
    ),
  );
}
