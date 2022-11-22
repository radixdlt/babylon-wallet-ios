import EngineToolkit
import Foundation

// MARK: - AlphanetAddresses
public enum AlphanetAddresses {}
public extension AlphanetAddresses {
	static let faucet: ComponentAddress = "system_tdx_a_1qsqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs2ufe42"
	static let createAccountComponent: PackageAddress = "package_tdx_a_1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqps373guw"
	static let xrd: ResourceAddress = "resource_tdx_a_1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqegh4k9"
}

public extension EngineToolkitClient {
	func createAccount(
		request withoutManifestRequest: BuildAndSignTransactionWithoutManifestRequest
	) throws -> SignedCompiledNotarizedTX {
		let engineToolkit = EngineToolkit()
		let nonFungibleAddressString = try engineToolkit.deriveNonFungibleAddressFromPublicKeyRequest(
			request: withoutManifestRequest.privateKey.publicKey().intoEngine()
		)
		.get()
		.nonFungibleAddress
		let nonFungibleAddress = try NonFungibleAddress(hex: nonFungibleAddressString)

		let manifest = TransactionManifest {
			CallMethod(
				receiver: AlphanetAddresses.faucet,
				methodName: "lock_fee"
			) {
				Decimal_(10.0)
			}

			CallMethod(
				receiver: AlphanetAddresses.faucet,
				methodName: "free_xrd"
			)

			let xrdBucket: Bucket = "xrd"

			TakeFromWorktop(resourceAddress: AlphanetAddresses.xrd, bucket: xrdBucket)

			CallFunction(
				packageAddress: AlphanetAddresses.createAccountComponent,
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

		return try sign(
			request: .init(manifest: manifest, withoutManifestRequest: withoutManifestRequest),
			engineToolkit: engineToolkit
		)
	}

	func sign(
		request: BuildAndSignTransactionWithManifestRequest,
		engineToolkit: EngineToolkit = .init()
	) throws -> SignedCompiledNotarizedTX {
		let privateKey = request.privateKey
		let headerInput = request.transactionHeaderInput

		let signTXRequest = try SignTransactionIntentRequest(
			manifest: request.manifest,
			headerInput: headerInput,
			privateKey: privateKey
		)

		return try signTransactionIntent(signTXRequest)
	}
}
