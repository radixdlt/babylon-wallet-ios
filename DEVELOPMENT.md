# Setup development
For getting started with development [read the setup development guide][devSetup].

# Overview

## Packages
We use the super modular design that Point-Free uses in [Isowords][isowordsPackage] - with almost 100 different packages.

## What do I import where?
  
We automatically link to all the below mentioned targets for each target type, i.e. no need to add `FeaturePrelude` as a dependency on a new target if you declare it using `feature(name:dependencies:tests:)`.

- If you're working on a **Feature** `import FeaturePrelude` 
- If you're working on a **Client**: `import ClientPrelude` 
- If you're writing tests for:
  - a **Client**: `import ClientTestingPrelude` 
  - a **Feature**: `import FeatureTestingPrelude`
  - **Core** or standalone module: `import TestingPrelude`

## Preview Apps
Thanks to TCA we can create Feature Previews, which are super small apps using a specific Feature's package as entry point, this is extremely useful, because suddenly we can start a small Preview App which takes us directly to Settings, or Directly directly to onboarding. See [Previews folder](/App/Previews) for our preview apps.


# Architecture
The Radix Wallet was originally developed under 2022/2023 using Xcode 13/14 using Swift 5.6, SwiftUI and [The Composable Architecture (TCA)][tca].

The Radix Wallet rests on several pillars:
* [Profile](./Sources/Profile): In the Radix Wallet the `Profile` is referred to as "wallet backup data", contains the list of all Accounts, Personas, Authorized Dapps, linked browsers, app settings and more. Securely stored in Keychain and by default backed-up to users iCloud Keychain.  
* [Radix Connect](./Sources/RadixConnect): Technology for safe, decentralized peer-to-peer communication between the [Radix Connector Extension][ce] and Radix Wallet, the underlying technology powering it is [WebRTC][webrtc]. 
* [Swift Engine Toolkit][set]: Swift wrapper around the Rust library [Radix Engine Toolkit - RET][ret] used to compile transaction intents into SBOR that the wallet signs, analyze transaction manifests, calculate transaction hashes and much much more.  


# Releasing
We make new releases using [fastlane][fastlane] (see [setup dev][devSetup]) which builds the app, uploads it to TestFlight and creates a new Github release.

## Versioning
We use SemVer, semantically versioning on format `MAJOR.MINOR.PATCH` (with a "build #\(BUILD)" suffix in UI).
Application version is specified in [Common.xcconfig](App/Config/Common.xcconfig), and is shared between all targets with their respective `.xcconfig` file.

[devSetup]: ./SETUP_DEV.md
[tca]: https://github.com/pointfreeco/swift-composable-architecture
[isowords]: https://github.com/pointfreeco/isowords
[isowordsPackage]: https://github.com/pointfreeco/isowords/blob/main/Package.swift
[ret]: https://github.com/radixdlt/radix-engine-toolkit
[set]: https://github.com/radixdlt/swift-engine-toolkit
[ce]: https://github.com/radixdlt/connector-extension
[fastlane]: https://docs.fastlane.tools/
[webrtc]: https://webrtc.org/