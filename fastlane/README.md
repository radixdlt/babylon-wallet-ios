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

### ios alpha_deploy

```sh
[bundle exec] fastlane ios alpha_deploy
```



### ios beta_deploy

```sh
[bundle exec] fastlane ios beta_deploy
```



### ios deploy

```sh
[bundle exec] fastlane ios deploy
```



### ios release_deploy

```sh
[bundle exec] fastlane ios release_deploy
```

Builds and deploys beta app to TestFlight

### ios install_certificates

```sh
[bundle exec] fastlane ios install_certificates
```

Installs certificates on the machine

### ios install_distribution_certificate

```sh
[bundle exec] fastlane ios install_distribution_certificate
```

Installs distribution certificate

### ios install_development_certificate

```sh
[bundle exec] fastlane ios install_development_certificate
```

Installs development certificate

### ios generate_new_certificates

```sh
[bundle exec] fastlane ios generate_new_certificates
```

Generates new certificates if needed

### ios generate_new_dev_certificates

```sh
[bundle exec] fastlane ios generate_new_dev_certificates
```

Generate new deve certificates

### ios generate_new_alpha_certificates

```sh
[bundle exec] fastlane ios generate_new_alpha_certificates
```

Generate new alpha certificates

### ios generate_new_beta_certificates

```sh
[bundle exec] fastlane ios generate_new_beta_certificates
```

Generate new beta certificates

### ios register_new_iphone_device

```sh
[bundle exec] fastlane ios register_new_iphone_device
```

Registers a new iPhone device and updates the certificates

----


## Mac

### mac tests

```sh
[bundle exec] fastlane mac tests
```

Runs tests

### mac install_certificates

```sh
[bundle exec] fastlane mac install_certificates
```

Installs certificates on the machine

### mac generate_new_certificates

```sh
[bundle exec] fastlane mac generate_new_certificates
```

Generates new certificates if needed

### mac register_new_mac_device

```sh
[bundle exec] fastlane mac register_new_mac_device
```

Registers a new mac device and updates the certificates

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
