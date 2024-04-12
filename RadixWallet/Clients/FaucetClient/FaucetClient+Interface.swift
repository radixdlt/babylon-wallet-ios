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

extension UserDefaults.Dependency {
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
		public init(accountAddress: AccountAddress, epoch: Epoch) {
			self.accountAddress = accountAddress
			self.epoch = epoch
		}
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
