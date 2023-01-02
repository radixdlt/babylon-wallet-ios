import Common
import Dependencies
import Foundation
import Profile
import TransactionClient

// MARK: - FaucetClient
public struct FaucetClient: Sendable {
	public var getFreeXRD: GetFreeXRD
	public var isAllowedToUseFaucet: IsAllowedToUseFaucet
	public var saveLastUsedEpoch: SaveLastUsedEpoch

	public init(
		getFreeXRD: @escaping GetFreeXRD,
		isAllowedToUseFaucet: @escaping IsAllowedToUseFaucet,
		saveLastUsedEpoch: @escaping SaveLastUsedEpoch
	) {
		self.getFreeXRD = getFreeXRD
		self.isAllowedToUseFaucet = isAllowedToUseFaucet
		self.saveLastUsedEpoch = saveLastUsedEpoch
	}
}

public extension FaucetClient {
	typealias GetFreeXRD = @Sendable (FaucetRequest) async throws -> TXID
	typealias IsAllowedToUseFaucet = @Sendable (AccountAddress) async throws -> Bool
	typealias SaveLastUsedEpoch = @Sendable (FaucetRequest) async throws -> Void
}

// MARK: FaucetClient.FaucetRequest
public extension FaucetClient {
	struct FaucetRequest: Sendable, Hashable {
		public let recipientAccountAddress: AccountAddress
		public let unlockKeychainPromptShowToUser: String
		public let addLockFeeInstructionToManifest: Bool
		public let makeTransactionHeaderInput: MakeTransactionHeaderInput
		public init(
			recipientAccountAddress: AccountAddress,
			unlockKeychainPromptShowToUser: String,
			addLockFeeInstructionToManifest: Bool = true,
			makeTransactionHeaderInput: MakeTransactionHeaderInput = .default
		) {
			self.recipientAccountAddress = recipientAccountAddress
			self.unlockKeychainPromptShowToUser = unlockKeychainPromptShowToUser
			self.addLockFeeInstructionToManifest = addLockFeeInstructionToManifest
			self.makeTransactionHeaderInput = makeTransactionHeaderInput
		}
	}
}

public extension DependencyValues {
	var faucetClient: FaucetClient {
		get { self[FaucetClient.self] }
		set { self[FaucetClient.self] = newValue }
	}
}
