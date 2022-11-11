# babylon-wallet-ios

An iOS wallet for interacting with the [Radix DLT ledger][radixdlt].

Writtin in Swift using SwiftUI as UI framework and [TCA - The Composable Architecture][tca] as architecture.

# Architecture
The structure is the same as [PointfreeCo's game Isowords (source)][isowords] (the authors of TCA). 

## SPM + App structure
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

# Package Graph
The proprietary package dependency graph for Babylon looks as follows:

```
Babylon
  │
  ╰─ Profile
  │    │
  ╰────╰─ EngineToolkit
       │    │
       ╰────╰─ SLIP10
       │         │
       ╰─────────╰─ Bite
       │         │
       ╰─────────╰─ Mnemonic
```

# Navigation
We are not doing navigation, for now. We defer choice of Navigation solution to "as late as possible". What this means is that we do not use any navigation stack, maybe no NavigationView, at all, for now. So we will have zero transition animation, and no automatic means of "go back" (which means that *for now* we will not try to impl any "go back" logic at all).

The reason for this is that some of us iOS devs still hope for Apple to back-deploy its new NavigationStack API introduced in iOS 16 to iOS 15. Maybe maybe they will do that.

Or PointFreeCo will make something amazing and iOS 15 compatible, follow [thread related to iOS 16 NavigationStack in TCA here](https://github.com/pointfreeco/swift-composable-architecture/discussions/1140).

So for now, we just use `IfletStore` and `SwitchStore` for displaying correct screen according to state.

# Code style

## No `protocol`s
We do not use Protocols at all (maybe with few rare exceptions), instead we use `struct` with closures. See section "Encapsulate ALL Dependencies" below for more info.

## No `class`es
We do not use classes at all (maybe with a few ultrarare exceptions), instead we use `struct` with closures. See section "Encapsulate ALL Dependencies" below for more info.

(Except for `final class MyTests: TestCase` (inheriting from `open class TestCase: XCTestCase` with some config) ofc...)

## SwiftFormat
We use SwiftFormat to format code, rules are defined in `.swiftformat`.

## Packages
We use the super modular design that PointFreeCo uses in [Isowords](https://github.com/pointfreeco/isowords/blob/main/Package.swift) - with almost 100 different packages. 

## Encapsulate ALL dependencies
We encapsulate ALL real world APIs, dependencies and inputs such as UserDefaults, Keychain, NotificationCenter, API Clients etc, we follow the pattern of [PointFreeCo's Isoword here UserDefaults][https://github.com/pointfreeco/isowords/tree/main/Sources/UserDefaultsClient]. 

```swift
public struct UserDefaultsClient {
  public var boolForKey: (String) -> Bool
  public var setBool: (Bool, String) -> Effect<Never, Never>


  public var hasShownFirstLaunchOnboarding: Bool {
    self.boolForKey(hasShownFirstLaunchOnboardingKey)
  }

  public func setHasShownFirstLaunchOnboarding(_ bool: Bool) -> Effect<Never, Never> {
    self.setBool(bool, hasShownFirstLaunchOnboardingKey)
  }
}

let hasShownFirstLaunchOnboardingKey = "hasShownFirstLaunchOnboardingKey"
let installationTimeKey = "installationTimeKey"
let multiplayerOpensCount = "multiplayerOpensCount"
```

Which does NOT use `protocol`s! We use structs with closures for each function as input, which makes mocking super easy.
Here is the Live version:

```swift
extension UserDefaultsClient {
  public static func live(
    userDefaults: UserDefaults = UserDefaults(suiteName: "group.isowords")!
  ) -> Self {
    Self(
      boolForKey: userDefaults.bool(forKey:),
      dataForKey: userDefaults.data(forKey:),
      doubleForKey: userDefaults.double(forKey:),
      integerForKey: userDefaults.integer(forKey:),
      remove: { key in
        .fireAndForget {
          userDefaults.removeObject(forKey: key)
        }
      },
      setBool: { value, key in
        .fireAndForget {
          userDefaults.set(value, forKey: key)
        }
      },
      setData: { data, key in
        .fireAndForget {
          userDefaults.set(data, forKey: key)
        }
      },
      setDouble: { value, key in
        .fireAndForget {
          userDefaults.set(value, forKey: key)
        }
      },
      setInteger: { value, key in
        .fireAndForget {
          userDefaults.set(value, forKey: key)
        }
      }
    )
  }
}
```

# Development
Clone the repo and run bootstrap script:
```sh
./scripts/bootstrap
```

To open the project use:

```sh
open App/BabylonWallet.xcodeproj
```

## Preview Packages
Thanks to TCA we can create Feature Previews, which are super small apps using a specific Feature's package as entry point, this is extremely useful, because suddenly we can start a small Preview App which takes us directly to Settings, or Directly directly to onboarding. See [Isowords Preview apps here](https://github.com/pointfreeco/isowords/tree/main/App/Previews).

instead of opening the root, otherwise you will not get access to the App and the Packages.

# Testing
1. Unit tests for each package, split into multiple files for each seperate system under test (sut).
2. UI testing using [PointFreeCo's Snapsshot testing Package][snapshotTesting] (Only when UI becomes stable)
3. Integration tests can be enabled later on using locally running Gateway service with Docker. Which has been [done before in ancient deprecated Swift SDK](https://github.com/radixdlt/radixdlt-swift-archive/tree/develop/Tests/TestCases/IntegrationTests)


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
[snapshotTesting]: https://github.com/pointfreeco/swift-snapshot-testing
