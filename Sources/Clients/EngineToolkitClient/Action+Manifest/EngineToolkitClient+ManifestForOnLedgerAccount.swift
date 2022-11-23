import EngineToolkit
import Foundation
import SLIP10

// MARK: - HammunetAddresses
public enum HammunetAddresses {}
public extension HammunetAddresses {
	static let faucet: ComponentAddress = "component_tdx_22_1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7ql6v973"

	/// For non-virtual accounts
	static let createAccountComponent: PackageAddress = "package_tdx_22_1qy4hrp8a9apxldp5cazvxgwdj80cxad4u8cpkaqqnhlsk0emdf"

	static let xrd: ResourceAddress = "resource_tdx_22_1qzxcrac59cy2v9lpcpmf82qel3cjj25v3k5m09rxurgqfpm3gw"
}

public extension EngineToolkitClient {
	func manifestForOnLedgerAccount(
		publicKey: PublicKey
	) throws -> TransactionManifest {
		try manifestForOnLedgerAccount(publicKey: publicKey.intoEngine())
	}

	func manifestForOnLedgerAccount(
		publicKey: Engine.PublicKey
	) throws -> TransactionManifest {
		let engineToolkit = EngineToolkit()

		let nonFungibleAddressString = try engineToolkit.deriveNonFungibleAddressFromPublicKeyRequest(
			request: publicKey
		)
		.get()
		.nonFungibleAddress

		let nonFungibleAddress = try NonFungibleAddress(hex: nonFungibleAddressString)

		return TransactionManifest {
			CallMethod(
				receiver: HammunetAddresses.faucet,
				methodName: "lock_fee"
			) {
				Decimal_(10.0)
			}

			CallMethod(
				receiver: HammunetAddresses.faucet,
				methodName: "free"
			)

			let xrdBucket: Bucket = "xrd"

			TakeFromWorktop(resourceAddress: HammunetAddresses.xrd, bucket: xrdBucket)

			CallFunction(
				packageAddress: HammunetAddresses.createAccountComponent,
				blueprintName: "Account",
				functionName: "new_with_resource"
			) {
				Enum("Protected") {
					Enum("ProofRule") {
						Enum("Require") {
							Enum("StaticNonFungible") {
								nonFungibleAddress
							}
						}
					}
				}
				xrdBucket
			}
		}
	}
}
