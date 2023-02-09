import ClientPrelude
import EngineToolkitClient
import GatewayAPI
import ProfileClient
import TransactionClient

// MARK: - FaucetClient + DependencyKey
extension FaucetClient: DependencyKey {
	public static let liveValue: Self = {
		@Dependency(\.userDefaultsClient) var userDefaultsClient
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.transactionClient) var transactionClient
		@Dependency(\.engineToolkitClient) var engineToolkitClient
		@Dependency(\.profileClient) var profileClient

		let getFreeXRD: GetFreeXRD = { faucetRequest in
			let networkID = await profileClient.getCurrentNetworkID()
			let manifest = try engineToolkitClient.manifestForFaucet(
				includeLockFeeInstruction: faucetRequest.addLockFeeInstructionToManifest,
				networkID: networkID,
				accountAddress: faucetRequest.recipientAccountAddress
			)

			let signSubmitTXRequest = SignManifestRequest(
				manifestToSign: manifest,
				makeTransactionHeaderInput: faucetRequest.makeTransactionHeaderInput,
				unlockKeychainPromptShowToUser: faucetRequest.unlockKeychainPromptShowToUser
			)

			let transactionID = try await transactionClient.signAndSubmitTransaction(signSubmitTXRequest).get()
//			try await saveLastUsedEpoch(faucetRequest)

			return transactionID
		}

		return Self(
			getFreeXRD: getFreeXRD,
			isAllowedToUseFaucet: { _ in true }, // TODO: @Nikola revert back to using isAllowedToUseFaucet after decoding is fixed
			saveLastUsedEpoch: { _ in } // FIXME: post betanet v2
		)
	}()
}
