# Overview

The structure is the same as [Point-Free's game Isowords (source)][isowords] (the authors of TCA).

## Packages
We use the super modular design that Point-Free uses in [Isowords](https://github.com/pointfreeco/isowords/blob/main/Package.swift) - with almost 100 different packages.

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


# Getting started

## Boot strap 
Clone the repo and run bootstrap script:
```sh
./scripts/bootstrap
```

Will will setup SwiftFormat to format code, rules are defined in `.swiftformat`.

### Open project
Open the `App/BabylonWallet.xcodeproj` and select the `Radix Wallet Dev (iOS)` scheme and hit run (`⌘R`).

## Fastlane

### Bundler setup
We use [Bundler](https://bundler.io/) to install and update Fastlane. Follow below steps to have Bundler installed and execute fastlane lanes:

- Install ruby v3.1.2; it is strongly recommend to use a tool like [rbenv](https://github.com/rbenv/rbenv) to manage the rubby version.
- Install bundler:

```sh
gem install bundler -v 2.3.25
```
- Install this project gems:

```sh
bundle install
```

### Certificates setup

- Download [fastlane secrets](https://start.1password.com/open/i?a=JWO4INKPOFHCDMZ2CYQMY4DRY4&v=srjnzoh2conosxfpkekxlakwzq&i=c75l3mugtfopfd5ebrcn22hssu&h=rdxworks.1password.com).
- Put the downloaded file in [fastlane](fastlane) folder. Be sure to remove the leading underscore from the file name.
- Run the below command to bring the necessary certificates for development:

```sh
bundle exec fastlane ios install_development_certificates
```

- If your device is unregistered, register it with the below command, it will prompt you to enter the device name and device UDID.

```sh
bundle exec fastlane ios register_new_iphone_device
```

After the above setup, you are good to go with building and running the app on iPhone. 
