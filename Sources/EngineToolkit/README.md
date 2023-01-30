# EngineToolkit 🛠 🧰

Swift EngineToolkit provides a high level functions and method for the interaction with the [Radix Engine Toolkit][ret].

# Binaries exluded
Binaries total size is 50+50+100 (iOS, iOS Sim, macOS (Intel/Apple Silicon)) mb for the three different `RadixEngineToolkit.a` files.

For now you need to build the [Radix Engine Toolkit][ret] yourself, using `build.sh`

# Supported Platforms
The underlying binary is built for these platforms:
* iOS (ARM64, used since [iPhone 5S][iphonearchs])
* iOS Simulator for both Apple Silicon (ARM64) and Intel (x86).
* macOS, both Apple Silicon (ARM64) and Intel (x86).

> Note: While x86 iOS versions are considered [obsolete][iphonearchs] they are still supported by the RadixEngineToolkit XCFramework to allow developers on Intel-based Macs to be able to use this library with their iPhone simulators.

# Build

This Package distributes the RadixEngineToolkit.XCFrmawork as an SPM binaryTarget, which has been build by the build script here in Radix Engine Toolkit repo.

The process of of building the Radix Engine Toolkit is outlined in their repo, found [here](https://github.com/radixdlt/radix-engine-toolkit).

# Declarative TransactionManifest syntax
Leveraging [`@resultBuilder` feature of Swift][resbuilder] combined with [`ExpressibleByIntegerLiteral`][expintlit], [`ExpressibleByStringLiteral`][expstrlit] etc Swift `EngineToolkit` enables you to write TransactionManifests using this clean syntax:

```swift
try TransactionManifest {
    
    // Withdraw XRD from account
    CallMethod(
        componentAddress: "account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064",
        methodName: "withdraw_by_amount"
    ) {
        Decimal_(5.0)
        ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag")
    }
    
    // Buy GUM with XRD
    TakeFromWorktopByAmount(
        amount: 2.0,
        resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag",
        bucket: "xrd"
    )
    CallMethod(
        componentAddress: "component_sim1q2f9vmyrmeladvz0ejfttcztqv3genlsgpu9vue83mcs835hum",
        methodName: "buy_gumball"
    ) { Bucket("xrd") }
    
    AssertWorktopContainsByAmount(
        amount: 3.0,
        resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag"
    )
    AssertWorktopContains(resourceAddress: "resource_sim1qzhdk7tq68u8msj38r6v6yqa5myc64ejx3ud20zlh9gseqtux6")
    
    // Create a proof from bucket, clone it and drop both
    TakeFromWorktop(
        resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag",
        bucket: "some_xrd"
    )
    CreateProofFromBucket(bucket: "some_xrd", proof: "proof1")
    CloneProof(from: "proof1", to: "proof2")
    DropProof("proof1")
    DropProof("proof2")
    
    // Create a proof from account and drop it
    CallMethod(
        componentAddress: "account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064",
        methodName: "create_proof_by_amount"
    ) {
        Decimal_(5.0)
        ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag")
    }
    
    PopFromAuthZone(proof: "proof3")
    DropProof("proof3")
    
    // Return a bucket to worktop
    ReturnToWorktop(bucket: "some_xrd")
    TakeFromWorktopByIds(
        [
            try NonFungibleLocalId(hex: "0905000000"),
            try NonFungibleLocalId(hex: "0907000000")
        ],
        resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag",
        bucket: "nfts"
    )
    
    // Create a new fungible resource
    CreateResource {
        Enum("Fungible") { U8(0) }
        Map(keyType: .string, valueType: .string)
        Map(keyType: .enum, valueType: .tuple)
        Option {
            Enum("Fungible") { Decimal_(1.0) }
        }
    }
    
    // Cancel all buckets and move resources to account
    CallMethod(
        componentAddress: "account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064",
        methodName: "deposit_batch"
    ) {
        Expression("ENTIRE_WORKTOP")
    }
    
    // Drop all proofs
    DropAllProofs()
    
    // Complicated method that takes all of the number types
    CallMethod(
        componentAddress: "component_sim1q2f9vmyrmeladvz0ejfttcztqv3genlsgpu9vue83mcs835hum",
        methodName: "complicated_method"
    ) {
        Decimal_(1)
        PreciseDecimal(2)
    }
}
```

Which is identical to declaring it using this multiline `String`:

```swift
"""
# Withdraw XRD from account
CALL_METHOD ComponentAddress("account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064") "withdraw_by_amount" Decimal("5.0") ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag");

# Buy GUM with XRD
TAKE_FROM_WORKTOP_BY_AMOUNT Decimal("2.0") ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag") Bucket("xrd");
CALL_METHOD ComponentAddress("component_sim1q2f9vmyrmeladvz0ejfttcztqv3genlsgpu9vue83mcs835hum") "buy_gumball" Bucket("xrd");
ASSERT_WORKTOP_CONTAINS_BY_AMOUNT Decimal("3.0") ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag");
ASSERT_WORKTOP_CONTAINS ResourceAddress("resource_sim1qzhdk7tq68u8msj38r6v6yqa5myc64ejx3ud20zlh9gseqtux6");

# Create a proof from bucket, clone it and drop both
TAKE_FROM_WORKTOP ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag") Bucket("some_xrd");
CREATE_PROOF_FROM_BUCKET Bucket("some_xrd") Proof("proof1");
CLONE_PROOF Proof("proof1") Proof("proof2");
DROP_PROOF Proof("proof1");
DROP_PROOF Proof("proof2");

# Create a proof from account and drop it
CALL_METHOD ComponentAddress("account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064") "create_proof_by_amount" Decimal("5.0") ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag");
POP_FROM_AUTH_ZONE Proof("proof3");
DROP_PROOF Proof("proof3");

# Return a bucket to worktop
RETURN_TO_WORKTOP Bucket("some_xrd");
TAKE_FROM_WORKTOP_BY_IDS Set<NonFungibleLocalId>(NonFungibleLocalId("0905000000"), NonFungibleLocalId("0907000000")) ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag") Bucket("nfts");

# Create a new fungible resource
CREATE_RESOURCE Enum("Fungible", 0u8) Map<String, String>() Map<Enum, Tuple>() Some(Enum("Fungible", Decimal("1.0")));

# Cancel all buckets and move resources to account
CALL_METHOD ComponentAddress("account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064") "deposit_batch" Expression("ENTIRE_WORKTOP");

# Drop all proofs
DROP_ALL_PROOFS;

# Complicated method that takes all of the number types
CALL_METHOD ComponentAddress("component_sim1q2f9vmyrmeladvz0ejfttcztqv3genlsgpu9vue83mcs835hum") "complicated_method" Decimal("1") PreciseDecimal("2");
"""
```

We make use of:
* [`ExpressibleByIntegerLiteral`][expintlit]
* [`ExpressibleByStringLiteral`][expstrlit]
* [`ExpressibleByFloatLiteral`][expfloatlit]
* [`ExpressibleByBooleanLiteral`][expboollit] 
* [`ExpressibleByNilLiteral`][expnillit] 

# Example
In order to run the example app, make sure to close down any other Xcode window which might have opened this SPM package and then standing in the root run:

```sh
open Example/AppTX.xcodeproj
```

**I have successfully run this example on an iPhone 7 (iOS 15.6.1)**

**I have successfully archived this example for iOS, resulting in an .xcarchive weighing 12.3 mb**

[ret]: https://github.com/radixdlt/radix-engine-toolkit
[iphonearchs]: https://docs.elementscompiler.com/Platforms/Cocoa/CpuArchitectures/
[resbuilder]: https://github.com/apple/swift-evolution/blob/main/proposals/0289-result-builders.md
[expstrlit]: https://developer.apple.com/documentation/swift/expressiblebystringliteral/
[expintlit]: https://developer.apple.com/documentation/swift/expressiblebyintegerliteral
[expfloatlit]: https://developer.apple.com/documentation/swift/expressiblebyfloatliteral
[expboollit]: https://developer.apple.com/documentation/swift/expressiblebybooleanliteral
[expnillit]: https://developer.apple.com/documentation/swift/expressiblebynilliteral
