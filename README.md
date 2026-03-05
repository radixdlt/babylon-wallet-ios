# Radix Wallet

<img align="left" src=".assetsReadme/app_icon_256.png" height="210" />

The Radix Wallet is your direct connection to the [Radix Network][dashboard], a decentralized platform designed specifically for great Web3 and DeFi dApps. Your Radix assets and identity are all held and managed in one convenient place, designed to connect seamlessly to Radix dApps.

The Radix Wallet can be downloaded from [the App Store][appStoreLink] (requires iOS 16.4).

[![Download Radix Wallet on the App Store](https://dbsqho33cgp4y.cloudfront.net/github/app-store-badge.png)][appStoreLink]

### Getting Started
Head over to [wallet.radixdlt.com][walletGuide] for guide on getting started using the Radix Wallet.

### Build Variants (Normal vs Light)

This repository includes two iOS project variants:

- **Normal**: `RadixWallet.xcodeproj`
- **Light**: `RadixWalletLight.xcodeproj`

Each variant has the same environment scheme set, where the Light variant adds the `Light` suffix:

- `Dev`: `Radix Wallet Dev` / `Radix Wallet Dev Light`
- `Alpha`: `Radix Wallet Alpha` / `Radix Wallet Alpha Light`
- `Pre-Alpha`: `Radix Wallet Pre-Alpha` / `Radix Wallet Pre-Alpha Light`
- `Beta`: `Radix Wallet Beta` / `Radix Wallet Beta Light`
- `PROD`: `Radix Wallet PROD` / `Radix Wallet PROD Light`

How to use:

1. Open the project matching your variant (`RadixWallet.xcodeproj` or `RadixWalletLight.xcodeproj`).
2. Select the matching scheme for your environment.
3. Build and run from Xcode as usual.

### Screenshots

<p float="middle">
  <img src=".assetsReadme/screenshots/start.png" width="200" />
  <img src=".assetsReadme/screenshots/home.png" width="200" /> 
  <img src=".assetsReadme/screenshots/transaction_review.png" width="200" /> 
  <img src=".assetsReadme/screenshots/dapp_request_account_permission.png" width="200" /> 
</p>

# Introduction
Create and manage Accounts that hold any type of asset on Radix (including the platform's native `XRD` token) displayed beautifully so you understand what you own at a glance. Create Personas to easily login to Radix dApps with one click. The Radix Wallet always makes sure that you're in control, with easy-to-understand transactions and clear dApp permissions so there are no surprises.

The Radix Wallet takes advantage of the advanced native features of the Radix Network. That means totally decentralized, non-custodial access to what you own; you always have direct access without any company in the middle.

# Contribute
To get started contributing to the Radix Wallet iOS code base [head over to the development guide](./DEVELOPMENT.md)

# License
The iOS Radix Wallet binaries are licensed under the [Radix Wallet Software EULA](https://www.radixdlt.com/terms/walletEULA).

The iOS Radix Wallet code is released under the [Apache 2.0 license](./LICENSE).


      Copyright 2023 Radix Publishing Ltd

      Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.

      You may obtain a copy of the License at: http://www.apache.org/licenses/LICENSE-2.0

      Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

      See the License for the specific language governing permissions and limitations under the License.


[dashboard]: https://dashboard.radixdlt.com
[radixdlt]: https://radixdlt.com
[appStoreLink]: https://apps.apple.com/se/app/radix-wallet/id6448950995
[walletGuide]: https://wallet.radixdlt.com

