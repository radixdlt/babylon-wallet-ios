import ClientPrelude
import Cryptography
import DeviceFactorSourceClient
import EngineKit
import TransactionClient

// MARK: - FaucetClient
public struct FaucetClient: Sendable {
	public var getFreeXRD: GetFreeXRD
	public var isAllowedToUseFaucet: IsAllowedToUseFaucet

	#if DEBUG
	public var createFungibleToken: CreateFungibleToken
	public var createNonFungibleToken: CreateNonFungibleToken

	public init(
		getFreeXRD: @escaping GetFreeXRD,
		isAllowedToUseFaucet: @escaping IsAllowedToUseFaucet,
		createFungibleToken: @escaping CreateFungibleToken,
		createNonFungibleToken: @escaping CreateNonFungibleToken
	) {
		self.getFreeXRD = getFreeXRD
		self.isAllowedToUseFaucet = isAllowedToUseFaucet
		self.createFungibleToken = createFungibleToken
		self.createNonFungibleToken = createNonFungibleToken
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
	public let numberOfTokens: Int

	public init(
		recipientAccountAddress: AccountAddress,
		name: String,
		symbol: String,
		numberOfTokens: Int = 1
	) {
		self.recipientAccountAddress = recipientAccountAddress
		self.name = name
		self.symbol = symbol
		self.numberOfTokens = numberOfTokens
	}

	public init(
		recipientAccountAddress: AccountAddress,
		numberOfTokens: Int = 1
	) {
		let randomName = BIP39.WordList.english.randomElement() ?? "Unnamed"

		self.init(
			recipientAccountAddress: recipientAccountAddress,
			name: randomName.lowercased(),
			symbol: randomName.uppercased(),
			numberOfTokens: numberOfTokens
		)
	}
}

public struct CreateNonFungibleTokenRequest: Sendable {
	public let recipientAccountAddress: AccountAddress
	public let name: String
	public let numberOfTokens: Int
	public let numberOfIds: Int

	public init(
		recipientAccountAddress: AccountAddress,
		name: String,
		numberOfTokens: Int = 1,
		numberOfIds: Int = 10
	) {
		self.recipientAccountAddress = recipientAccountAddress
		self.name = name
		self.numberOfTokens = numberOfTokens
		self.numberOfIds = numberOfIds
	}

	public init(
		recipientAccountAddress: AccountAddress,
		numberOfTokens: Int = 1,
		numberOfIds: Int = 10
	) {
		let randomName = BIP39.WordList.english.randomElement() ?? "Unnamed"

		self.init(
			recipientAccountAddress: recipientAccountAddress,
			name: randomName.lowercased(),
			numberOfTokens: numberOfTokens,
			numberOfIds: numberOfIds
		)
	}
}
#endif // DEBUG

extension FaucetClient {
	public typealias GetFreeXRD = @Sendable (FaucetRequest) async throws -> Void
	public typealias IsAllowedToUseFaucet = @Sendable (AccountAddress) async -> Bool

	#if DEBUG
	public typealias CreateFungibleToken = @Sendable (CreateFungibleTokenRequest) async throws -> Void
	public typealias CreateNonFungibleToken = @Sendable (CreateNonFungibleTokenRequest) async throws -> Void
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

extension UserDefaultsClient {
	public func loadEpochForWhenLastUsedByAccountAddress() -> EpochForWhenLastUsedByAccountAddress {
		(try? loadCodable(key: .epochForWhenLastUsedByAccountAddress)) ?? .init()
	}

	public func saveEpochForWhenLastUsedByAccountAddress(_ value: EpochForWhenLastUsedByAccountAddress) async {
		// not important enough to propagate error
		try? await save(codable: value, forKey: .epochForWhenLastUsedByAccountAddress)
	}
}

// MARK: - EpochForWhenLastUsedByAccountAddress
// internal for tests
public struct EpochForWhenLastUsedByAccountAddress: Codable, Hashable, Sendable {
	public struct EpochForAccount: Codable, Sendable, Hashable, Identifiable {
		public typealias ID = AccountAddress
		public var id: ID { accountAddress }
		public let accountAddress: AccountAddress
		public var epoch: Epoch
	}

	public var epochForAccounts: IdentifiedArrayOf<EpochForAccount>
	public init(epochForAccounts: IdentifiedArrayOf<EpochForAccount> = .init()) {
		self.epochForAccounts = epochForAccounts
	}

	public mutating func update(epoch: Epoch, for id: AccountAddress) {
		if var existing = epochForAccounts[id: id] {
			existing.epoch = epoch
			epochForAccounts[id: id] = existing
		} else {
			epochForAccounts.append(.init(accountAddress: id, epoch: epoch))
		}
	}

	public func getEpoch(for accountAddress: AccountAddress) -> Epoch? {
		epochForAccounts[id: accountAddress]?.epoch
	}
}
