# Getting started

## Bootstrap 
Clone the repo and run bootstrap script:

```sh
./scripts/bootstrap
```

Will will setup SwiftFormat to format code, rules are defined in `.swiftformat`.

## Open project

```sh
open App/BabylonWallet.xcodeproj
```

Select the `Radix Wallet Dev (iOS)` scheme and hit run (`⌘R`).

## Fastlane

### Setup `ruby`
Install ruby `>v3.1.2`; it is strongly recommend to use a tool like [rbenv][rbenv] to manage the ruby version.


### Setup `bundler`
We use [bundler][bundler] to install and update Fastlane. Follow below steps to have Bundler installed and execute fastlane lanes:

- Install bundler:

```sh
gem install bundler -v 2.3.25
```

- Install this project gems:

```sh
bundle install
```

### Setup `fastlane`

- Download [fastlane secrets][secret] (requires RDX Works 1Password access).
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

[rbenv]: https://github.com/rbenv/rbenv
[bundler]: https://bundler.io
[secret]: https://start.1password.com/open/i?a=JWO4INKPOFHCDMZ2CYQMY4DRY4&v=srjnzoh2conosxfpkekxlakwzq&i=c75l3mugtfopfd5ebrcn22hssu&h=rdxworks.1password.com