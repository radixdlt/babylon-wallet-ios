# Getting started

## Bootstrap 
Clone the repo and run bootstrap script:

```sh
./scripts/bootstrap
```

Will will setup SwiftFormat to format code, rules are defined in `.swiftformat`.

## Open project

```sh
open RadixWallet.xcodeproj
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

### Setup secrets

There are two types of secrets required by the project: `General` & `Fastlane`. In order to download them, you will need access to RDX Works 1Password team.  
Once you have it, you will be to download each secrets file and place it in the folder detailed in the next steps. After downloading each file, be sure to remove the leading underscore from the file name.

- Download [general secrets][general_secrets] and put the downloaded file in root folder.
- Download [fastlane secrets][fastlane_secrets] and put the downloaded file in [fastlane](fastlane) folder.

### Setup `fastlane`

- Run the below command to bring the necessary certificates for development:

```sh
bundle exec fastlane install_development_certificates
```

- If your device is unregistered, register it with the below command, it will prompt you to enter the device name and device UDID.

```sh
bundle exec fastlane register_new_device
```

After the above setup, you are good to go with building and running the app on iPhone. 

[rbenv]: https://github.com/rbenv/rbenv
[bundler]: https://bundler.io
[general_secrets]: https://rdx.works
[fastlane_secrets]: https://start.1password.com/open/i?a=JWO4INKPOFHCDMZ2CYQMY4DRY4&v=btoakzspnaugf5miuybcfh5fey&i=xpfwvtmc65hbja4xwujp2e6vfq&h=rdxworks.1password.com
