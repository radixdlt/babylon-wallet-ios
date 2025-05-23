fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build

```sh
[bundle exec] fastlane ios build
```

Builds and archives the app

### ios tests

```sh
[bundle exec] fastlane ios tests
```

Runs test

### ios create_sensitive_info

```sh
[bundle exec] fastlane ios create_sensitive_info
```

Creates SensitiveInfo.plist if it doesn't exist

### ios create_google_service_info

```sh
[bundle exec] fastlane ios create_google_service_info
```

Creates GoogleService-Info.plist if it doesn't exist

### ios populate_sensitive_info

```sh
[bundle exec] fastlane ios populate_sensitive_info
```

Populates SensitiveInfo.plist with environment values

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

Deploy the app for a given flavour: alpha, beta, release

Usage `bundle exec fastlane ios deploy --env ios.<specific env>`

### ios export_ios_app

```sh
[bundle exec] fastlane ios export_ios_app
```

Archive and export the iOS app

### ios install_distribution_certificates

```sh
[bundle exec] fastlane ios install_distribution_certificates
```

Installs distribution certificates

Usage `bundle exec fastlane ios install_distribution_certificates --env ios.<specific env>`

### ios install_development_certificates

```sh
[bundle exec] fastlane ios install_development_certificates
```

Installs development certificates

### ios generate_new_dev_certificates

```sh
[bundle exec] fastlane ios generate_new_dev_certificates
```

Generate new dev certificates

### ios generate_new_appstore_certificates

```sh
[bundle exec] fastlane ios generate_new_appstore_certificates
```

Generate new appstore certificates

Usage bundle exec fastlane ios generate_new_appstore_certificates --env ios.<specific env>

### ios register_new_device

```sh
[bundle exec] fastlane ios register_new_device
```

Registers a new iPhone/Mac device and updates the certificates

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
