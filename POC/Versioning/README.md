# PoC Versioning

I've identified fundamentally two different solutions:
1. One single type for each model, where different versions are handled inside decoder.
	a. Single global shared version number, trinkled down using [`CodableWithConfiguration`](https://developer.apple.com/documentation/foundation/codablewithconfiguration) ([intro here](https://www.andyibanez.com/posts/the-mysterious-codablewithconfiguration-protocol/))
	b. Unique per type version number
2. Multiple types for each model, using [`VersionedCodable` package](https://github.com/jrothwell/VersionedCodable)

**A solution is only viable if it also works for Android**


|                            | Multiple types? | Global version? | Advantages | Disadvantages                                                                                                                          |
|----------------------------|-----------------|-------------------------------|------------|----------------------------------------------------------------------------------------------------------------------------------------|
| Single type global version | No              | Yes            | Convenient to only have one single type, less verbose JSON.     | Explosion in complexity for different combinations of migrations => **error prone**. More increments of version than if using unique.  |
| Single type unique version | No              | No             | Convenient to only have one single type. Less increments to `Profile.version`  |  Explosion in complexity for different combinations of migrations => **error prone**. More verbose JSON than if using global version.  |
| Multiple types             | Yes             | No             |  Safest, structured linear handling of incremental upgrades.     		|  Many many many types, especially since we use nested types. |