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
	func createAccount(request: BuildAndSignTransactionRequest) throws -> SignedCompiledNotarizedTX {
		let privateKey = request.privateKey
		let headerInput = request.transactionHeaderInput

		let engineToolkit = EngineToolkit()
		let nonFungibleAddressString = try engineToolkit.deriveNonFungibleAddressFromPublicKeyRequest(
			request: privateKey.publicKey().intoEngine()
		)
		.get()
		.nonFungibleAddress
		let nonFungibleAddress = try NonFungibleAddress(hex: nonFungibleAddressString)

		let manifest = TransactionManifest {
			CallMethod(
				componentAddress: AlphanetAddresses.faucet,
				methodName: "lock_fee"
			) {
				Decimal_(10.0)
			}

			CallMethod(
				componentAddress: AlphanetAddresses.faucet,
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

		let signTXRequest = try SignTransactionIntentRequest(
			manifest: manifest,
			headerInput: headerInput,
			privateKey: privateKey
		)

		return try signTransactionIntent(signTXRequest)
	}
}
