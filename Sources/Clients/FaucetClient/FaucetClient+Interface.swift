import ClientPrelude
import TransactionClient

// MARK: - FaucetClient
public struct FaucetClient: Sendable {
	public var getFreeXRD: GetFreeXRD
	public var isAllowedToUseFaucet: IsAllowedToUseFaucet

	public init(
		getFreeXRD: @escaping GetFreeXRD,
		isAllowedToUseFaucet: @escaping IsAllowedToUseFaucet
	) {
		self.getFreeXRD = getFreeXRD
		self.isAllowedToUseFaucet = isAllowedToUseFaucet
	}
}

extension FaucetClient {
	public typealias GetFreeXRD = @Sendable (FaucetRequest) async throws -> Void
	public typealias IsAllowedToUseFaucet = @Sendable (AccountAddress) async -> Bool
}

// MARK: FaucetClient.FaucetRequest
extension FaucetClient {
	public struct FaucetRequest: Sendable, Hashable {
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

extension DependencyValues {
	public var faucetClient: FaucetClient {
		get { self[FaucetClient.self] }
		set { self[FaucetClient.self] = newValue }
	}
}
