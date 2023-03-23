import ClientPrelude
import Cryptography
import TransactionClient

// MARK: - FaucetClient
public struct FaucetClient: Sendable {
	public var getFreeXRD: GetFreeXRD
	public var isAllowedToUseFaucet: IsAllowedToUseFaucet

	#if DEBUG
	public var createFungibleToken: CreateFungibleToken
	public init(
		getFreeXRD: @escaping GetFreeXRD,
		isAllowedToUseFaucet: @escaping IsAllowedToUseFaucet,
		createFungibleToken: @escaping CreateFungibleToken
	) {
		self.getFreeXRD = getFreeXRD
		self.isAllowedToUseFaucet = isAllowedToUseFaucet
		self.createFungibleToken = createFungibleToken
	}
	#else
	public init(
		getFreeXRD: @escaping GetFreeXRD,
		isAllowedToUseFaucet: @escaping IsAllowedToUseFaucet
	) {
		self.getFreeXRD = getFreeXRD
		self.isAllowedToUseFaucet = isAllowedToUseFaucet
	}
	#endif // DEBUG
}

#if DEBUG
public struct CreateFungibleTokenRequest: Sendable {
	public let recipientAccountAddress: AccountAddress
	public let name: String
	public let symbol: String

	public init(
		recipientAccountAddress: AccountAddress,
		name: String,
		symbol: String
	) {
		self.recipientAccountAddress = recipientAccountAddress
		self.name = name
		self.symbol = symbol
	}

	public init(
		recipientAccountAddress: AccountAddress
	) {
		let randomName = BIP39.WordList.english.randomElement() ?? "Unnamed"

		self.init(
			recipientAccountAddress: recipientAccountAddress,
			name: randomName.lowercased(),
			symbol: randomName.uppercased()
		)
	}
}
#endif // DEBUG

extension FaucetClient {
	public typealias GetFreeXRD = @Sendable (FaucetRequest) async throws -> Void
	public typealias IsAllowedToUseFaucet = @Sendable (AccountAddress) async -> Bool
	#if DEBUG
	public typealias CreateFungibleToken = @Sendable (CreateFungibleTokenRequest) async throws -> Void
	#endif // DEBUG
}

// MARK: FaucetClient.FaucetRequest
extension FaucetClient {
	public struct FaucetRequest: Sendable, Hashable {
		public let recipientAccountAddress: AccountAddress
		public init(
			recipientAccountAddress: AccountAddress
		) {
			self.recipientAccountAddress = recipientAccountAddress
		}
	}
}

extension DependencyValues {
	public var faucetClient: FaucetClient {
		get { self[FaucetClient.self] }
		set { self[FaucetClient.self] = newValue }
	}
}
