## 1.0.0

Initial release, extracted from an internal application module where these
casts back roughly seventy request and response models.

- Strict and nullable casts for the JSON primitives — `asString`, `asCleanUrl`,
  `asDouble`, `asInt`, `asBool` and `asDateTime` — each taking the field's name
  and throwing a `FormatException` that quotes both the name and the offending
  value.
- Lenient input by design: numeric strings with grouping commas, `0`/`1` and
  `yes`/`no` booleans, and epoch timestamps in seconds or milliseconds, since
  these are what financial APIs actually send.
- `asMap` and `asList<T>` for nested structures, replacing unchecked
  `as Map<String, dynamic>` and `as List<dynamic>` casts. `asList` names the
  failing entry by index — `"trades[3]"` — and its element callback receives
  that indexed name, so a whole path can be built up.
- `asStringList` and `asMapList` shorthands.
- A `SafeJsonMap` extension on `Map<String, dynamic>` mirroring every cast, so
  a field is named once (`json.asDouble('lastPrice')`) rather than twice.
- `hasKey`, to tell an absent field from one present and null — the casts treat
  the two alike.
- Dartdoc across the public API, a runnable `example/`, and 58 tests.
