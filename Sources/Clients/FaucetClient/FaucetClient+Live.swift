import Common
import Dependencies
import EngineToolkit
import EngineToolkitClient
import Foundation
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

		let isAllowedToUseFaucet: IsAllowedToUseFaucet = { accountAddress in
			guard let encodedEpoch = userDefaultsClient.dataForKey(epochsForAccountAddressesUserDefaultsKey) else {
				return true
			}

			do {
				let epochs = try JSONDecoder().decode(EpochsForAccountAddresses.self, from: encodedEpoch)
				guard let lastUsedEpoch = epochs.getEpoch(for: accountAddress) else {
					return true
				}

				let currentEpoch = try await gatewayAPIClient.getEpoch()

				let treshold = 200
				return currentEpoch.rawValue - lastUsedEpoch.rawValue >= treshold
			} catch {
				throw error
			}
		}

		let saveLastUsedEpoch: SaveLastUsedEpoch = { faucetRequest in
			let epoch = try await gatewayAPIClient.getEpoch()
			let account = faucetRequest.recipientAccountAddress

			var epochs: EpochsForAccountAddresses
			if let encodedEpoch = userDefaultsClient.dataForKey(epochsForAccountAddressesUserDefaultsKey) {
				epochs = try JSONDecoder().decode(EpochsForAccountAddresses.self, from: encodedEpoch)
			} else {
				epochs = .init()
			}

			epochs.update(epoch: epoch, for: account)

			do {
				let encodedEpochs = try JSONEncoder().encode(epochs)
				await userDefaultsClient.setData(encodedEpochs, epochsForAccountAddressesUserDefaultsKey)
			} catch {
				throw error
			}
		}

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
			try await saveLastUsedEpoch(faucetRequest)

			return transactionID
		}

		return Self(
			getFreeXRD: getFreeXRD,
			isAllowedToUseFaucet: isAllowedToUseFaucet,
			saveLastUsedEpoch: saveLastUsedEpoch
		)
	}()
}

private extension FaucetClient {
	static var epochsForAccountAddressesUserDefaultsKey: String { "faucet.epochsForAccountAddresses" }

	struct EpochsForAccountAddresses: Sendable, Hashable, Codable {
		private var dictionary = [AccountAddress: Epoch]()

		mutating func update(epoch: Epoch, for accountAddress: AccountAddress) {
			dictionary[accountAddress] = epoch
		}

		func getEpoch(for accountAddress: AccountAddress) -> Epoch? {
			dictionary[accountAddress]
		}
	}
}
