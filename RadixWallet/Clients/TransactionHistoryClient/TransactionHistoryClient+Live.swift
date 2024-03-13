import EngineToolkit

extension TransactionHistoryClient {
	public static let liveValue = TransactionHistoryClient.live()

	public static func live() -> Self {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

		@Sendable
		func getTransactionHistory(_ request: TransactionHistoryRequest) async throws -> TransactionHistoryResponse {
			let response = try await gatewayAPIClient.streamTransactions(request.gatewayRequest)
			let account = request.account
			let networkID = try account.networkID()
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
			let groupedNonFungibleIDs = Dictionary(grouping: nonFungibleIDs) { $0.resourceAddress() }
			let nonFungibleTokenArrays = try await groupedNonFungibleIDs.parallelMap { address, ids in
				try await onLedgerEntitiesClient.getNonFungibleTokenData(.init(resource: address.asSpecific(), nonFungibleIds: ids))
			}
			var keyedNonFungibleTokens: IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken> = []
			for nonFungibleTokenArray in nonFungibleTokenArrays {
				keyedNonFungibleTokens.append(contentsOf: nonFungibleTokenArray)
			}

			func nonFungibleResources(_ type: ChangeType, changes: GatewayAPI.TransactionNonFungibleBalanceChanges) async throws -> [ResourceBalance] {
				let address = try ResourceAddress(validatingAddress: changes.resourceAddress)

				// The resource should have been fetched
				guard let resource = keyedResources[id: address] else { throw ProgrammerError() }

				if let validator = await onLedgerEntitiesClient.isStakeClaimNFT(resource) {
					return try [onLedgerEntitiesClient.stakeClaim(resource, stakeClaimValidator: validator, unstakeData: [], tokens: [])]
				} else {
					let nonFungibleIDs = try extractNonFungibleIDs(type, from: changes)
					return try nonFungibleIDs
						.map { id in
							// All tokens should have been fetched earlier
							guard let token = keyedNonFungibleTokens[id: id] else { throw ProgrammerError() }
							return token
						}
						.map { token in
							ResourceBalance(resource: resource, details: .nonFungible(token))
						}
				}
			}

			let dateformatter1 = ISO8601DateFormatter()
			dateformatter1.formatOptions.insert(.withFractionalSeconds)
			let dateformatter2 = ISO8601DateFormatter()

			func transaction(for info: GatewayAPI.CommittedTransactionInfo) async throws -> TransactionHistoryItem {
				let time = dateformatter1.date(from: info.roundTimestamp)
					?? dateformatter2.date(from: info.roundTimestamp)
					?? info.confirmedAt

				guard let time else {
					struct CorruptTimestamp: Error { let roundTimestamd: String }
					throw CorruptTimestamp(roundTimestamd: info.roundTimestamp)
				}

				let manifestClass = info.manifestClasses?.first

				guard info.receipt?.status == .committedSuccess else {
					return .failed(at: time, manifestClass: manifestClass)
				}

				let message = info.message?.plaintext?.content.string

				var withdrawals: [ResourceBalance] = []
				var deposits: [ResourceBalance] = []

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

						let amount = try RETDecimal(value: fungible.balanceChange)
						guard !amount.isZero() else { continue }

						// NB: The sign of the amount in the balance is made positive, negative balances are treated as withdrawals
						let resource = try await onLedgerEntitiesClient.fungibleResourceBalance(
							baseResource,
							resourceQuantifier: .guaranteed(amount: amount.abs()),
							networkID: networkID
						)

						if amount.isNegative() {
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
			if !request.parameters.backwards {
				items.reverse()
			}

			return .init(
				parameters: request.parameters,
				nextCursor: response.nextCursor,
				totalCount: response.totalCount,
				resources: keyedResources,
				items: items
			)

//			return try await .init(
//				cursor: response.nextCursor,
//				items: response.items.parallelMap(transaction(for:))
//			)
		}

		return TransactionHistoryClient(
			getTransactionHistory: getTransactionHistory
		)
	}

	@Sendable
	private static func extractResourceAddresses(from changes: GatewayAPI.TransactionBalanceChanges) throws -> [ResourceAddress] {
		try (changes.fungibleBalanceChanges.map(\.resourceAddress)
			+ changes.nonFungibleBalanceChanges.map(\.resourceAddress))
			.map(ResourceAddress.init)
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
	private static func extractNonFungibleIDs(_ type: ChangeType, from changes: GatewayAPI.TransactionNonFungibleBalanceChanges) throws -> [NonFungibleGlobalId] {
		let localIDStrings = type == .added ? changes.added : changes.removed
		let resourceAddress = try EngineToolkit.Address(address: changes.resourceAddress)
		return try localIDStrings
			.map(nonFungibleLocalIdFromStr)
			.map { try NonFungibleGlobalId.fromParts(resourceAddress: resourceAddress, nonFungibleLocalId: $0) }
	}
}

extension TransactionHistoryItem {
	static func failed(at time: Date, manifestClass: GatewayAPI.ManifestClass?) -> Self {
		.init(
			time: time,
			message: nil,
			manifestClass: manifestClass,
			withdrawals: [],
			deposits: [],
			depositSettingsUpdated: false,
			failed: true
		)
	}
}

extension TransactionHistoryRequest {
	var gatewayRequest: GatewayAPI.StreamTransactionsRequest {
		.init(
			atLedgerState: .init(timestamp: parameters.period.upperBound),
			fromLedgerState: .init(timestamp: parameters.period.lowerBound),
			cursor: cursor,
			limitPerPage: 10,
			manifestResourcesFilter: manifestResourcesFilter(parameters.filters),
			affectedGlobalEntitiesFilter: [account.address],
			eventsFilter: eventsFilter(parameters.filters, account: account),
			manifestClassFilter: manifestClassFilter(parameters.filters),
			order: parameters.backwards ? .desc : .asc,
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
			.map { .init(_class: $0, matchOnlyMostSpecific: false) }
	}

	private func manifestResourcesFilter(_ filters: [TransactionFilter]) -> [String]? {
		filters
			.compactMap(\.asset?.address)
			.nilIfEmpty
	}
}

extension SpecificAddress {
	public func networkID() throws -> NetworkID {
		try .init(intoEngine().networkId())
	}
}
