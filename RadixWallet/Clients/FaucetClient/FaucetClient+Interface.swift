// MARK: - FaucetClient
struct FaucetClient: Sendable {
	var getFreeXRD: GetFreeXRD
	var isAllowedToUseFaucet: IsAllowedToUseFaucet

	init(
		getFreeXRD: @escaping GetFreeXRD,
		isAllowedToUseFaucet: @escaping IsAllowedToUseFaucet
	) {
		self.getFreeXRD = getFreeXRD
		self.isAllowedToUseFaucet = isAllowedToUseFaucet
	}
}

extension FaucetClient {
	typealias GetFreeXRD = @Sendable (FaucetRequest) async throws -> Void
	typealias IsAllowedToUseFaucet = @Sendable (AccountAddress) async -> Bool
}

// MARK: FaucetClient.FaucetRequest
extension FaucetClient {
	struct FaucetRequest: Sendable, Hashable {
		let recipientAccountAddress: AccountAddress
		init(
			recipientAccountAddress: AccountAddress
		) {
			self.recipientAccountAddress = recipientAccountAddress
		}
	}
}

extension DependencyValues {
	var faucetClient: FaucetClient {
		get { self[FaucetClient.self] }
		set { self[FaucetClient.self] = newValue }
	}
}

extension UserDefaults.Dependency {
	func loadEpochForWhenLastUsedByAccountAddress() -> EpochForWhenLastUsedByAccountAddress {
		(try? loadCodable(key: .epochForWhenLastUsedByAccountAddress)) ?? .init()
	}

	func saveEpochForWhenLastUsedByAccountAddress(_ value: EpochForWhenLastUsedByAccountAddress) async {
		// not important enough to propagate error
		try? await save(codable: value, forKey: .epochForWhenLastUsedByAccountAddress)
	}
}

// MARK: - EpochForWhenLastUsedByAccountAddress
// internal for tests
struct EpochForWhenLastUsedByAccountAddress: Codable, Hashable, Sendable {
	struct EpochForAccount: Codable, Sendable, Hashable, Identifiable {
		typealias ID = AccountAddress
		var id: ID { accountAddress }
		let accountAddress: AccountAddress
		var epoch: Epoch
		init(accountAddress: AccountAddress, epoch: Epoch) {
			self.accountAddress = accountAddress
			self.epoch = epoch
		}
	}

	var epochForAccounts: IdentifiedArrayOf<EpochForAccount>
	init(epochForAccounts: IdentifiedArrayOf<EpochForAccount> = .init()) {
		self.epochForAccounts = epochForAccounts
	}

	mutating func update(epoch: Epoch, for id: AccountAddress) {
		if var existing = epochForAccounts[id: id] {
			existing.epoch = epoch
			epochForAccounts[id: id] = existing
		} else {
			epochForAccounts.append(.init(accountAddress: id, epoch: epoch))
		}
	}

	func getEpoch(for accountAddress: AccountAddress) -> Epoch? {
		epochForAccounts[id: accountAddress]?.epoch
	}
}
