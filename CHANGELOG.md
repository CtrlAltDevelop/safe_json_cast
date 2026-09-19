## 1.2.0

Bug fixes that tighten what the numeric casts accept, plus the move to the
shared CI and a Dart 3 floor. No signature changed.

- **Non-finite numbers are rejected.** `asDouble` and `asNum` no longer return
  `NaN` or an infinity — from a number, from `'NaN'` / `'Infinity'`, or from
  `'1e999'` overflowing — and `NaN` can no longer slip past `min` / `max`,
  where every comparison is false. This is the failure the package exists to
  stop; a payload that relied on receiving one now throws.
- **No more stray `UnsupportedError` or `RangeError`.** `asInt`, `asDateTime`
  and `asDuration` used to throw those for `NaN`, infinities and out-of-range
  numbers, which `tryCast` and `on FormatException` did not catch. They now
  throw `JsonCastException` naming the field.
- `asDateTime` rejects an epoch outside the ±100,000,000 days `DateTime` can
  hold. A second-precision value near 9.2e15 used to wrap around in the
  multiplication and could land on a plausible date; it now throws.
- `asDuration` rejects a magnitude past 2^53 microseconds (about 285 years)
  instead of clamping it silently, so a value reads the same on the web.
- `asInt` reads a string of plain digits as an integer rather than through a
  `double`, so `'9007199254740993'` keeps its last digit.
- `asBool` rejects `NaN` instead of reading it as `true`.
- **The SDK floor moves to Dart 3.12.0**, from Dart 2.15.0 — the floor every
  package here is gated on. The source now uses switch patterns and switch
  expressions in `asBool`, `asDateTime` and `asDuration`.
- CI moved to the shared reusable workflow in CtrlAltDevelop/ci-workflows:
  formatting, `analyze --fatal-infos`, the tests, the example, a changelog
  entry per version, and a pana score with no points lost.
- Dependency bounds are explicit ranges rather than carets, so a consumer
  already on an older version in the same major is not forced to move.
- The README carries the pub, pub points, CI and licence badges the other
  packages here carry.
- 35 new tests, 155 in all.

## 1.1.1

- The SDK floor drops to Dart 2.15 — Flutter 2.8 — from 3.12, widening who can
  depend on this without changing anything about what it does. That is as low
  as the code allows: 2.15 is where `Enum` and `Enum.name` arrived, and
  `asEnum` is built on them.
- The three constructs that had been holding the floor at Dart 3 were rewritten
  in terms that predate it — a record in the path walker, a switch expression
  in `asDuration`, an unnamed `library` directive. None was load-bearing, and
  no behaviour changed with them: the same 120 tests pass.

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
