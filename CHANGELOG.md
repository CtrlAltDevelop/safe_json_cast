## 1.1.0

Additive throughout — every 1.0.0 call site compiles unchanged, and the
exception messages are byte-for-byte what they were.

- `JsonCastException`, thrown by every cast. It extends `FormatException`, so
  existing `on FormatException` handlers and message assertions keep working,
  and it exposes the same information as data — `field`, `value` and
  `expectedType` — for code that reports a bad payload rather than printing it.
- **Paths.** `castAt` reads a nested leaf in one step and reports the whole
  path as the field name: `json.castAt('data.orders[0].price', asDouble)` fails
  as `Field "data.orders[0].price"="n/a"`. `valueAt` returns the raw value,
  `hasPath` answers for a path what `hasKey` answers for a key, and both are
  available as the bare `valueAtPath` / `pathExists` for a non-map root. An
  absent step resolves to `null`; a step that is present but not walkable —
  indexing into a string — throws, naming the part of the path that worked.
- **Bounds.** `asDouble`, `asInt` and `asNum` take `min` and `max`, so a
  negative quantity or a percentage above 100 fails at the parse site rather
  than wherever it is first used. Inclusive, checked after conversion.
- `asNum`, for a field that is honestly either an `int` or a `double` and
  should not be rounded through one of them.
- `asBigInt`, for ids and balances that overflow a Dart `int` on the web. A
  fractional value is rejected rather than truncated.
- `asUri`, so a malformed URL fails at the parse site instead of at the request
  that would have used it.
- `asStrictString`, the counterpart to `asString` for fields where a number
  arriving in place of a string is a bug rather than something to coerce, and
  `asNonEmptyString`, because an API that sends `""` for an id is claiming to
  have sent one.
- `asDuration` with `DurationUnit` — seconds by default, since that is what
  `expiresIn` and `ttl` usually mean. No unit guessing: a duration carries no
  magnitude that would give its unit away, so the caller states it.
- `asEnum`, matching an enum by name case-insensitively, with a `wireNames` map
  for the spellings that differ — `PARTIALLY_FILLED` to `partiallyFilled`. The
  failure lists the accepted names.
- `asMapOf<T>`, for the objects an API uses as a dictionary — a balance per
  asset, a label per locale. Names the failing entry by key: `"balances.BTC"`.
- `asSet<T>` and the `asStringSet` shorthand, for the arrays an API uses as a
  set. Order preserved; a repeat collapses by default, or throws under
  `allowDuplicates: false`, naming the entry that repeated.
- `asIntList` and `asDoubleList`, alongside the existing list shorthands.
- `EpochUnit` on `asDateTime`, to read a numeric timestamp in a known unit —
  including microseconds — rather than the magnitude guess, which stays the
  default.
- `growable` on `asList`, for the callers that were copying the result.
- `tryCast`, which turns a failed cast into `null` so a deliberate default
  stays visible at the call site: `tryCast(() => json.asDouble('fee')) ?? 0`.
- 120 tests, up from 58.

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
