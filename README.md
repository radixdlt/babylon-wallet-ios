# babylon-wallet-swift

An iOS wallet for interacting with the [Radix DLT ledger][radixdlt].

Writtin in Swift using SwiftUI as UI framework and [TCA - The Composable Architecture][tca] as architecture.

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

[radixdlt]: https://radixdlt.com
[tca]: https://github.com/pointfreeco/swift-composable-architecture
[isowords] https://github.com/pointfreeco/isowords
