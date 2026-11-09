# swift-rfc-9557

Use this package when you need to read or write timestamps that carry a time zone name, a calendar or other tags in brackets after an RFC 3339 date-time, as in `1996-12-19T16:39:57-08:00[America/Los_Angeles][u-ca=hebrew]`. Start from `RFC_9557.Timestamp`, and from `RFC_9557.Suffix` for the bracketed part alone. If you only need plain RFC 3339 date-times, use swift-rfc-3339.

## Laws

- A plain RFC 3339 date-time is a valid timestamp, with no suffix. Otherwise everything from the first `[` on is the suffix, and a suffix is bracketed annotations only, with nothing between or after them.
- The time zone is not checked against the offset, so `2022-07-08T00:14:07Z[Europe/Paris]` is accepted.
- A bracket without `=` is the time zone, and a suffix may have only one. A time zone starting with `+` or `-` is an offset, written as an RFC 3339 offset such as `+08:45`. Anything else is a time zone name, checked for syntax only and kept as written, so `Europe/Paris` and `europe/paris` are different time zones.
- Each part of a time zone name, between slashes, is non-empty, starts with a letter, a dot or an underscore, and is not just one or two dots.
- A tag key is lowercase letters, digits, hyphens and underscores, and starts with a lowercase letter or an underscore. A tag value is one or more runs of letters and digits joined by hyphens, read as separate values.
- A key starting with `_` is experimental, and both parsing and `RFC_9557.Suffix.Tag` refuse it whether or not it is critical.
- A tag marked critical with `!` is refused unless its key is registered. The only registered key is `u-ca`. An unknown tag that is not critical is kept.
- `u-ca` sets the calendar to its first value, kept as written, and keeps its critical flag. When a key appears more than once, the first occurrence wins and the rest are dropped.
- A suffix is written as the time zone, then the calendar, then the other tags in the order they were read.
- A suffix built in code follows the same rules as a parsed one: its time zone and calendar are checked, its tags may not repeat a key or use `u-ca`, so what it writes parses back to it.
