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

			print("• RESPONSE: \(request.period.lowerBound.formatted(date: .abbreviated, time: .omitted)) -> \(request.period.upperBound.formatted(date: .abbreviated, time: .omitted)) \(response.items.count) •••••••••••••••••••••••")

			print("•• GET RES: period: \(resourcesForPeriod.count), overall: \(resourcesNeededOverall.count), needed: \(resourcesToLoad.count) -> total: \(keyedResources.count) loaded now: \(loadedResources.count)")

			for red in keyedResources {
				print("    •• res: \(red.metadata.title ?? "-"): already loaded: \(request.resources.ids.contains(red.id))")
			}

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

			let dateformatter = ISO8601DateFormatter()
			dateformatter.formatOptions.insert(.withFractionalSeconds)

			func transaction(for info: GatewayAPI.CommittedTransactionInfo) async throws -> TransactionHistoryItem {
				guard let time = dateformatter.date(from: info.roundTimestamp) else {
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

			return .init(cursor: nil, resources: keyedResources, items: items)

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

// MARK: - TransactionInfo
struct TransactionInfo: Sendable {
	static let timestampFormatter: ISO8601DateFormatter = {
		let dateformatter = ISO8601DateFormatter()
		dateformatter.formatOptions.insert(.withFractionalSeconds)
		return dateformatter
	}()

	let time: Date
	let message: String?
	let manifestClass: GatewayAPI.ManifestClass?
//	let fungibleBalanceChanges: String
//	let nonFungibleBalanceChanges: String
	let depositSettingsUpdated: Bool
	let failed: Bool
}

extension TransactionInfo {
	init(info: GatewayAPI.CommittedTransactionInfo) throws {
		guard let time = TransactionInfo.timestampFormatter.date(from: info.roundTimestamp) else {
			struct CorruptTimestamp: Error { let roundTimestamd: String }
			throw CorruptTimestamp(roundTimestamd: info.roundTimestamp)
		}

		let message = info.message?.plaintext?.content.string
		let manifestClass = info.manifestClasses?.first
		guard info.receipt?.status == .committedSuccess else {
			self.init(time: time, message: message, manifestClass: manifestClass, depositSettingsUpdated: false, failed: true)
			return
		}

		let changes = info.balanceChanges

		let depositSettingsUpdated = info.manifestClasses?.contains(.accountDepositSettingsUpdate) == true

		self.init(
			time: time,
			message: message,
			manifestClass: manifestClass,
			depositSettingsUpdated: depositSettingsUpdated,
			failed: false
		)
	}
}

extension TransactionHistoryRequest {
	var gatewayRequest: GatewayAPI.StreamTransactionsRequest {
		.init(
			atLedgerState: .init(timestamp: period.upperBound),
			fromLedgerState: .init(timestamp: period.lowerBound),
			cursor: cursor,
			limitPerPage: 100,
//				kindFilter: T##GatewayAPI.StreamTransactionsRequest.KindFilter,
//				manifestAccountsWithdrawnFromFilter: <#T##[String]?#>,
//				manifestAccountsDepositedIntoFilter: <#T##[String]?#>,
			manifestResourcesFilter: manifestResourcesFilter(filters),
			affectedGlobalEntitiesFilter: [account.address],
			eventsFilter: eventsFilter(filters, account: account),
//				accountsWithManifestOwnerMethodCalls: <#T##[String]?#>,
//				accountsWithoutManifestOwnerMethodCalls: <#T##[String]?#>,
			manifestClassFilter: manifestClassFilter(filters),
			order: ascending ? .asc : .desc,
			optIns: .init(balanceChanges: true)
			// optIns: GatewayAPI.TransactionDetailsOptIns(affectedGlobalEntities: true, manifestInstructions: true, balanceChanges: true)
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
