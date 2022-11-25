import Common
import Dependencies
import EngineToolkitClient
import Foundation
import GatewayAPI
import ProfileClient
import TransactionClient

public extension FaucetClient {
	static func live() -> Self {
		let isAllowedToUseFaucet: IsAllowedToUseFaucet = { accountAddress in
			@Dependency(\.gatewayAPIClient) var gatewayAPIClient
			@Dependency(\.userDefaultsClient) var userDefaultsClient

			guard let encodedEpoch = userDefaultsClient.dataForKey(lastUsedEpochUserDefaultsKey(for: accountAddress)) else {
				return true
			}

			do {
				let lastUsedEpoch = try JSONDecoder().decode(LastUsedEpoch.self, from: encodedEpoch)
				let currentEpoch = try await gatewayAPIClient.getEpoch()
				let treshold = 200
				return Int(currentEpoch.rawValue) - lastUsedEpoch.epoch >= treshold
			} catch {
				throw error
			}
		}

		let saveLastUsedEpoch: SaveLastUsedEpoch = { faucetRequest in
			@Dependency(\.gatewayAPIClient) var gatewayAPIClient
			@Dependency(\.userDefaultsClient) var userDefaultsClient

			let epoch = try await gatewayAPIClient.getEpoch()
			let account = faucetRequest.recipientAccountAddress
			let lastUsedEpoch = LastUsedEpoch(epoch: Int(epoch.rawValue))

			do {
				let encodedEpoch = try JSONEncoder().encode(lastUsedEpoch)
				await userDefaultsClient.setData(encodedEpoch, lastUsedEpochUserDefaultsKey(for: account))
			} catch {
				throw error
			}
		}

		let getFreeXRD: GetFreeXRD = { faucetRequest in
			@Dependency(\.transactionClient) var transactionClient
			@Dependency(\.engineToolkitClient) var engineToolkitClient
			@Dependency(\.profileClient) var profileClient

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
			try await saveLastUsedEpoch(faucetRequest)

			return transactionID
		}

		return Self(
			getFreeXRD: getFreeXRD,
			isAllowedToUseFaucet: isAllowedToUseFaucet,
			saveLastUsedEpoch: saveLastUsedEpoch
		)
	}
}

public extension FaucetClient {
	static func lastUsedEpochUserDefaultsKey(for accountAddress: AccountAddress) -> String {
		"faucet.lastUsedEpoch.account-\(accountAddress.address)"
	}

	struct LastUsedEpoch: Codable {
		let epoch: Int
	}
}

// MARK: - FaucetClient + DependencyKey
extension FaucetClient: DependencyKey {
	public static var liveValue: FaucetClient = .live()
}
