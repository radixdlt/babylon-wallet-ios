
extension TransactionHistoryClient {
	static let liveValue = TransactionHistoryClient.live()

	static func live() -> Self {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

		struct CorruptTimestamp: Error { let roundTimestamd: String }
		struct MissingIntentHash: Error {}

		let dateFormatter = TimestampFormatter()

		@Sendable
		func getFirstTransactionDate(_ account: AccountAddress) async throws -> Date? {
			@Dependency(\.cacheClient) var cacheClient

			if let date = try? cacheClient.load(Date.self, .dateOfFirstTransaction(account)) as? Date {
				return date
			}

			let response = try await gatewayAPIClient.streamTransactions(
				.init(
					limitPerPage: 1,
					affectedGlobalEntitiesFilter: [account.address],
					order: .asc
				)
			)

			guard let info = response.items.first else { return nil }

			guard let date = dateFormatter.date(from: info.roundTimestamp) ?? info.confirmedAt else {
				throw CorruptTimestamp(roundTimestamd: info.roundTimestamp)
			}

			cacheClient.save(date, .dateOfFirstTransaction(account))

			return date
		}

		@Sendable
		func getTransactionHistory(_ request: TransactionHistoryRequest) async throws -> TransactionHistoryResponse {
			let response = try await gatewayAPIClient.streamTransactions(request.gatewayRequest)
			let account = request.account
			let resourcesForPeriod = try Set(response.items.flatMap { try $0.balanceChanges.map(extractResourceAddresses) ?? [] })
			let resourcesNeededOverall = request.allResourcesAddresses.union(resourcesForPeriod)
			let existingResources = request.resources.ids
			let resourcesToLoad = resourcesNeededOverall.subtracting(existingResources)
			let loadedResources = try await onLedgerEntitiesClient.getResources(resourcesToLoad)
			var keyedResources = request.resources
			keyedResources.append(contentsOf: loadedResources)

			// Thrown if a resource or nonFungibleToken that we loaded is not present, should never happen
			struct ProgrammerError: Error {}

			// Loading all NFT data

			let nonFungibleIDs = try Set(response.items.flatMap { try $0.balanceChanges.map(extractAllNonFungibleIDs) ?? [] })
			let groupedNonFungibleIDs = Dictionary(grouping: nonFungibleIDs) { $0.resourceAddress }
			let nonFungibleTokenArrays = try await groupedNonFungibleIDs.parallelMap { address, ids in
				try await onLedgerEntitiesClient.getNonFungibleTokenData(.init(resource: address, nonFungibleIds: ids))
			}
			var keyedNonFungibleTokens: IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken> = []
			for nonFungibleTokenArray in nonFungibleTokenArrays {
				keyedNonFungibleTokens.append(contentsOf: nonFungibleTokenArray)
			}

			func nonFungibleResources(_ type: ChangeType, changes: GatewayAPI.TransactionNonFungibleBalanceChanges) async throws -> [KnownResourceBalance] {
				let address = try ResourceAddress(validatingAddress: changes.resourceAddress)

				// The resource should have been fetched
				guard let resource = keyedResources[id: address] else {
					throw ProgrammerError()
				}

				// Will be non-nil if this is a stake claim NFT (or multiple)
				let stakeClaimNFT = try await onLedgerEntitiesClient.isStakeClaimNFT(resource)
					.map { validator in
						try onLedgerEntitiesClient.stakeClaim(
							resource,
							stakeClaimValidator: validator,
							unstakeData: [:],
							tokens: []
						)
					}

				return try extractNonFungibleIDs(type, from: changes)
					.map { id in
						if let stakeClaimNFT {
							return stakeClaimNFT
						} else {
							guard let token = keyedNonFungibleTokens[id: id] else { throw ProgrammerError() }
							return KnownResourceBalance(resource: resource, details: .nonFungible(.token(token)))
						}
					}
			}

			func transaction(for info: GatewayAPI.CommittedTransactionInfo) async throws -> TransactionHistoryItem {
				guard let time = dateFormatter.date(from: info.roundTimestamp) ?? info.confirmedAt else {
					throw CorruptTimestamp(roundTimestamd: info.roundTimestamp)
				}
				guard let hash = info.intentHash else {
					throw MissingIntentHash()
				}

				let txid = try TransactionIntentHash(hash)

				let manifestClass = info.manifestClasses?.first

				guard info.receipt?.status == .committedSuccess else {
					return .init(
						id: txid,
						time: time,
						manifestClass: manifestClass,
						failed: true
					)
				}

				let message = info.message?.plaintext?.content.string

				var withdrawals: [KnownResourceBalance] = []
				var deposits: [KnownResourceBalance] = []

				if let changes = info.balanceChanges {
					for nonFungible in changes.nonFungibleBalanceChanges where nonFungible.entityAddress == account.address {
						let withdrawn = try await nonFungibleResources(.removed, changes: nonFungible)
						withdrawals.append(contentsOf: withdrawn)
						let deposited = try await nonFungibleResources(.added, changes: nonFungible)
						deposits.append(contentsOf: deposited)
					}

					for fungible in changes.fungibleBalanceChanges where fungible.entityAddress == account.address {
						let resourceAddress = try ResourceAddress(validatingAddress: fungible.resourceAddress)
						guard let baseResource = keyedResources[id: resourceAddress] else {
							throw ProgrammerError()
						}

						let amount = try Decimal192(fungible.balanceChange)
						guard !amount.isZero else { continue }

						// NB: The sign of the amount in the balance is made positive, negative balances are treated as withdrawals
						let resource = try await onLedgerEntitiesClient.fungibleResourceBalance(
							baseResource,
							resourceQuantifier: .guaranteed(decimal: amount.abs()),
							networkID: account.networkID
						)

						if amount.isNegative {
							withdrawals.append(resource)
						} else {
							deposits.append(resource)
						}
					}
				}

				withdrawals.sort()
				deposits.sort()

				let depositSettingsUpdated = info.manifestClasses?.contains(.accountDepositSettingsUpdate) == true

				return .init(
					id: txid,
					time: time,
					message: message,
					manifestClass: manifestClass,
					withdrawals: withdrawals,
					deposits: deposits,
					depositSettingsUpdated: depositSettingsUpdated,
					failed: false
				)
			}

			var items: [TransactionHistoryItem] = []

			for item in response.items {
				let transactionItem = try await transaction(for: item)
				items.append(transactionItem)
			}

			if request.parameters.direction == .up {
				items.reverse()
			}

			return .init(
				nextCursor: response.nextCursor,
				resources: keyedResources,
				items: items
			)
		}

		return TransactionHistoryClient(
			getFirstTransactionDate: getFirstTransactionDate,
			getTransactionHistory: getTransactionHistory
		)
	}

	@Sendable
	private static func extractResourceAddresses(from changes: GatewayAPI.TransactionBalanceChanges) throws -> [ResourceAddress] {
		try (changes.fungibleBalanceChanges.map(\.resourceAddress)
			+ changes.nonFungibleBalanceChanges.map(\.resourceAddress))
			.map(ResourceAddress.init(validatingAddress:))
	}

	@Sendable
	private static func extractAllNonFungibleIDs(from changes: GatewayAPI.TransactionBalanceChanges) throws -> [NonFungibleGlobalId] {
		try changes.nonFungibleBalanceChanges.flatMap { change in
			try extractNonFungibleIDs(.added, from: change) + extractNonFungibleIDs(.removed, from: change)
		}
	}

	enum ChangeType {
		case added, removed
	}

	@Sendable
	private static func extractNonFungibleIDs(
		_ type: ChangeType,
		from changes: GatewayAPI.TransactionNonFungibleBalanceChanges
	) throws -> [NonFungibleGlobalId] {
		let localIDStrings = type == .added ? changes.added : changes.removed
		let resourceAddress = try ResourceAddress(validatingAddress: changes.resourceAddress)
		return try localIDStrings
			.map(NonFungibleLocalId.init)
			.map { NonFungibleGlobalId(resourceAddress: resourceAddress, nonFungibleLocalId: $0) }
	}

	struct TimestampFormatter {
		let formatter = ISO8601DateFormatter()
		let fractionalFormatter = ISO8601DateFormatter()

		init() {
			self.fractionalFormatter.formatOptions.insert(.withFractionalSeconds)
		}

		func date(from string: String) -> Date? {
			formatter.date(from: string) ?? fractionalFormatter.date(from: string)
		}
	}
}

extension TransactionHistoryRequest {
	var gatewayRequest: GatewayAPI.StreamTransactionsRequest {
		.init(
			atLedgerState: parameters.period.upperBound.map { .init(timestamp: $0) },
			fromLedgerState: parameters.period.lowerBound.map { .init(timestamp: $0) },
			cursor: cursor,
			limitPerPage: 20,
			manifestResourcesFilter: manifestResourcesFilter(parameters.filters),
			affectedGlobalEntitiesFilter: [account.address],
			eventsFilter: eventsFilter(parameters.filters, account: account),
			manifestClassFilter: manifestClassFilter(parameters.filters),
			order: parameters.direction == .down ? .desc : .asc,
			optIns: .init(balanceChanges: true)
		)
	}

	private func eventsFilter(_ filters: [TransactionFilter], account: AccountAddress) -> [GatewayAPI.StreamTransactionsRequestEventFilterItem]? {
		filters
			.compactMap(\.transferType)
			.map { transferType in
				switch transferType {
				case .deposit: .init(event: .deposit, emitterAddress: account.address)
				case .withdrawal: .init(event: .withdrawal, emitterAddress: account.address)
				}
			}
			.nilIfEmpty
	}

	private func manifestClassFilter(_ filters: [TransactionFilter]) -> GatewayAPI.StreamTransactionsRequestAllOfManifestClassFilter? {
		filters
			.compactMap(\.transactionType)
			.first
			.map { .init(_class: $0, matchOnlyMostSpecific: true) }
	}

	private func manifestResourcesFilter(_ filters: [TransactionFilter]) -> [String]? {
		filters
			.compactMap(\.asset?.address)
			.nilIfEmpty
	}
}
