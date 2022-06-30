# babylon-wallet-ios

An iOS wallet for interacting with the [Radix DLT ledger][radixdlt].

Writtin in Swift using SwiftUI as UI framework and [TCA - The Composable Architecture][tca] as architecture.

# Architecture
The structure is the same as [PointfreeCo's game Isowords (source)][isowords] (the authors of TCA). 

A "gotcha" of this structure is that the project root contains the Package.swift and `Source` and `Tests` of the Swift Packages. The actual app is an ultra thin entrypoint, using `AppFeature` package, and is put in `App` folder. This is how the app references the local packages:

1. Select the project in the Navigator
2. Target "Wallet (iOS)"
3. Build Phases
4. Link Binary With Libraries
5. "+"button in bottom of section
6. "Add Other" button in bottom left
7. "Add Package Dependency"
8. And selecting the whole project ROOT (yes the root, and we will use a trick below to avoid "recursion")
9. This would not work if we did not use PointfreeCos trick to create a "Dummy" Package.swift inside `./App/` folder, which we have done. 
10. Again click "+"button in bottom of "Link Binary With Libraries" section and you should see "AppFeature" (and all other packages) there, add "AppFeature"!
11. This setup only needs to happen once, for all targets, but any other targets need to perform the last step, of adding the actual package as dependency, e.g. for macOS (for development purpuses).

# Development
To open the project use:

```sh
open App/Wallet.xcodeproj
```

instead of opening the root, otherwise you will not get access to the App and the Packages.

# Releasing

## Versioning
We use SemVer, semantically versioning on format `MAJOR.MINOR.PATCH` (with a "build #\(BUILD)" suffix in UI).

To to update the version number or build number, you only have to change the value in one place (disregarding of targets) and that is in Project Settings (not target) and scroll down to the buttom under "User-Defined" section an update values of keys accordinly:

```
BUILD_NUMBER_GLOBAL_UNIQUE
BUILD_VERSION_MAJOR
BUILD_VERSION_MINOR
BUILD_VERSION_PATCH
```

Note that `BUILD_NUMBER_GLOBAL_UNIQUE` is not per version, it is a "globally unique" number, which always should uniquely identify the build.

If you add a new target you need to go to "Build Settings" for the new target and under section "Versioning":
set `MARKETING_VERSION` to `$(BUILD_VERSION_MAJOR).$(BUILD_VERSION_MINOR).$(BUILD_VERSION_PATCH)` 
and set `CURRENT_PROJECT_VERSION` to `$(BUILD_NUMBER_GLOBAL_UNIQUE)`.

[radixdlt]: https://radixdlt.com
[tca]: https://github.com/pointfreeco/swift-composable-architecture
[isowords]: https://github.com/pointfreeco/isowords
