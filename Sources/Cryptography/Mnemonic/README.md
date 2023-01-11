# Mnemonic

A BIP39 implementation in pure Swift.


# Usage

## CLI

### Generate Now
```sh
git clone --depth 1 git@github.com:radixdlt/Mnemonic.git && cd Mnemonic && sh generate.sh && cd .. && rm -rf Mnemonic
```

### Run in terminal (CLI support)

```zsh
swift run bip39 --word-count 24 --language English | less
```

The piping to `less` is of course optional - but recommended for maximum security (it automatically clears the password from your screen after you press `Q` to exit `less`).

Or use the shell script:

```zsh
sh generate.sh
```

#### Options
View help of command by running:

```sh
swift run bip39 --help`
```

Which will show you information about *word count* and *language* options.

##### Word Count
You can chose between 12, 15, 18, 21 and 24 mnemonic words.

##### Languages
All BIP39 languages are supported, which are:
* 🇨🇳 Chinese (simplified and traditional) 
* 🇨🇿 Czech 
* 🇬🇧 English 
* 🇫🇷 French 
* 🇮🇹 Italian  
* 🇯🇵 Japanese  
* 🇰🇷 Korean
* 🇪🇸 Spanish

###### Chinese
For Chinese, please specify in quoutes either "Chinese Simplified" or "Chinese Traditional"

```sh
swift run bip39 -l "Chinese Simplified"
```

## Code

### Overview

```swift
let mnemonic = try Mnemonic(wordCount: .twentyFour, language: .english) // generate new

// Use caution when accessing `phrase`, `words`, `seed` and `entropy`, these are hyper sensitive and should in general not be printed.

print(mnemonic.phrase) // "oxygen depth gain embrace scrap hub turkey laptop tilt venue whisper boil tree vacuum expire two box wheat own system fence swallow mistake soda"

let entropy = mnemonic.entropy() // CSPRNG generated entopy used to create the mnemonic
let seed = try mnemonic.seed(passphrase: "cerberus") // for HD wallets

print(mnemonic.language) // "English"
print(mnemonic.wordCount) // "24 words."
```

### Generate new

```swift
let mnemonic = try Mnemonic()

// Which is the same as:
let mnemonic = try Mnemonic(wordCount: .default, language: .default)

// Which is the same as:
let mnemonic = try Mnemonic.generate(wordCount: .default, language: .default)

// Which is the same as:
let mnemonic = try Mnemonic(wordCount: .twentyFour, language: .english)
```

### Restore
```swift
let mnemonic = try Mnemonic(phrase: "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about")

// But you can help the program a little bit and save some nanosecond, by specifying the language
let mnemonic = try Mnemonic(phrase: "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about", language: .english)
```

### Seed
```swift
let mnemonic = try Mnemonic()
let seed = try mnemonic.seed(passphrase: "cerberus")
// Can now create a BIP32 HD wallet.
```

### Entropy
```swift
let mnemonicGenerated = try Mnemonic()
let mnemonicFromEntropy = try Mnemonic(entropy: mnemonicGenerated.entropy())
assert(mnemonicFromEntropy.entropy() == mnemonicGenerated.entropy()) // passes
assert(mnemonicFromEntropy.phrase == mnemonicGenerated.phrase) // passes
```

# Installation

Installable via [Swift Package Manager (SPM)](https://swift.org/package-manager/):


## Package.swift file
Add in your `Package.swift` file

```swift
dependencies: [
    .package(url: "https://github.com/radixdlt/Mnemonic", from: "0.0.1"),
],
```

**- or -**

## Xcode
From Xcode, you can use SPM to add `Mnemonic` to your project:

1.  Select File > Swift Packages > Add Package Dependency, Enter
`https://github.com/radixdlt/Mnemonic.git` in the *"Choose Package Repository"* dialog.
2.  In the next page, specify the version resolving rule as "Up to Next Major" with "0.0.1" as its earliest version.
3.  After Xcode checking out the source and resolving the version, you can choose the "Mnemonic" library and add it to your app target.

If you encounter any problem or have a question on adding package to an Xcode project, take a look at the [Adding Package Dependencies to Your App](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app) guide article from Apple.

