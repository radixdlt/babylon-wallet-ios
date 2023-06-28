# PoC Versioning

I've identified fundamentally two different solutions:
1. One single type for each model, where different versions are handled inside decoder.
	a. Single global shared version number, trinkled down using [`CodableWithConfiguration`](https://developer.apple.com/documentation/foundation/codablewithconfiguration) ([intro here](https://www.andyibanez.com/posts/the-mysterious-codablewithconfiguration-protocol/))
	b. Unique per type version number
2. Multiple types for each model, using [`VersionedCodable` package](https://github.com/jrothwell/VersionedCodable)

**A solution is only viable if it also works for Android**

