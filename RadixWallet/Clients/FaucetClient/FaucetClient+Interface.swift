// MARK: - FaucetClient
struct FaucetClient {
	var getFreeXRD: GetFreeXRD
	var isAllowedToUseFaucet: IsAllowedToUseFaucet
}

extension FaucetClient {
	typealias GetFreeXRD = @Sendable (FaucetRequest) async throws -> Void
	typealias IsAllowedToUseFaucet = @Sendable (AccountAddress) async -> Bool
}

// MARK: FaucetClient.FaucetRequest
extension FaucetClient {
	struct FaucetRequest: Hashable {
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
struct EpochForWhenLastUsedByAccountAddress: Codable, Hashable {
	struct EpochForAccount: Codable, Hashable, Identifiable {
		typealias ID = AccountAddress
		var id: ID {
			accountAddress
		}

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
