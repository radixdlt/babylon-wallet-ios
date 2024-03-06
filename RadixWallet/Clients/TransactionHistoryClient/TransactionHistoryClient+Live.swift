import EngineToolkit

extension SpecificAddress {
	public func networkID() throws -> NetworkID {
		try .init(intoEngine().networkId())
	}
}

extension TransactionHistoryClient {
	private static func eventsFilter(_ filters: [TransactionFilter], account: AccountAddress) -> [GatewayAPI.StreamTransactionsRequestEventFilterItem]? {
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

	private static func manifestClassFilter(_ filters: [TransactionFilter]) -> GatewayAPI.StreamTransactionsRequestAllOfManifestClassFilter? {
		filters
			.compactMap(\.transactionType)
			.first
			.map { .init(_class: $0, matchOnlyMostSpecific: false) }
	}

	private static func manifestResourcesFilter(_ filters: [TransactionFilter]) -> [String]? {
		filters
			.compactMap(\.asset?.address)
			.nilIfEmpty
	}

	public static let liveValue = TransactionHistoryClient.live()

	public static func live() -> Self {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

		@Sendable
		func getTransactionHistory(
			account: AccountAddress,
			period: Range<Date>,
			filters: [TransactionFilter],
			ascending: Bool,
			cursor: String?
		) async throws -> TransactionHistoryResponse {
			let networkID = try account.networkID()

			var account = account
			if networkID == .mainnet {
				// FIXME: GK REMOVE THIS
				account = try AccountAddress(validatingAddress: "account_rdx128z7rwu87lckvjd43rnw0jh3uczefahtmfuu5y9syqrwsjpxz8hz3l")
			}

			let request = GatewayAPI.StreamTransactionsRequest(
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

			let response = try await gatewayAPIClient.streamTransactions(request)

			// Pre-loading the details for all the resources involved

			// an LSU: resource_rdx1nfuz9wd3laurnsveh32wuurh0c2t8ceg8hgvdkzl22ex9gqk9cqd2p

			print("• RESPONSE: \(period.lowerBound.formatted(date: .abbreviated, time: .omitted)) -> \(period.upperBound.formatted(date: .abbreviated, time: .omitted)) \(response.items.count) •••••••••••••••••••••••")

			let resourceAddresses = try Set(response.items.flatMap { try $0.balanceChanges.map(extractResourceAddresses) ?? [] })
			let resourceDetails = try await onLedgerEntitiesClient.getResources(resourceAddresses)
			let keyedResources = IdentifiedArray(uniqueElements: resourceDetails)

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
				let message = info.message?.plaintext?.content.string
				let manifestClass = info.manifestClasses?.first

				var withdrawals: [ResourceBalance] = []
				var deposits: [ResourceBalance] = []

				var ww = 0
				var dd = 0

				var nn = 0
				var ff = 0

				var n = 0
				var f = 0

				if let changes = info.balanceChanges {
					nn = changes.nonFungibleBalanceChanges.count
					n = changes.nonFungibleBalanceChanges.filter { $0.entityAddress == account.address }.count
					ff = changes.fungibleBalanceChanges.count
					f = changes.fungibleBalanceChanges.filter { $0.entityAddress == account.address }.count

					for nonFungible in changes.nonFungibleBalanceChanges {
						ww += try await nonFungibleResources(.removed, changes: nonFungible).count
						dd += try await nonFungibleResources(.added, changes: nonFungible).count
						guard nonFungible.entityAddress == account.address else { continue }

//					for nonFungible in changes.nonFungibleBalanceChanges where nonFungible.entityAddress == account.address {
						let withdrawn = try await nonFungibleResources(.removed, changes: nonFungible)
						withdrawals.append(contentsOf: withdrawn)
						let deposited = try await nonFungibleResources(.added, changes: nonFungible)
						deposits.append(contentsOf: deposited)

						for w in withdrawn {
							print(" ••  \(w.resource.metadata.title) \(w.resource.id.address)")
						}
					}

					for fungible in changes.fungibleBalanceChanges {
						let amount_ = try RETDecimal(value: fungible.balanceChange)
						if amount_.isPositive() {
							dd += 1
						} else if amount_.isNegative() {
							ww += 1
						}

						guard fungible.entityAddress == account.address else { continue }

//					for fungible in changes.fungibleBalanceChanges where fungible.entityAddress == account.address {

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

				withdrawals.sort(by: >)
				deposits.sort(by: >)

				print("••• \(time.formatted(date: .abbreviated, time: .shortened)) \(info.manifestClasses?.first?.rawValue ?? "---") N: \(nn) \(n), F: \(ff) \(f)  W: \(ww) \(withdrawals.count), D: \(dd) \(deposits.count)")

				return .init(
					time: time,
					message: message,
					manifestClass: manifestClass,
					withdrawals: withdrawals,
					deposits: deposits,
					depositSettingsUpdated: info.manifestClasses?.contains(.accountDepositSettingsUpdate) == true
				)
			}

			var items: [TransactionHistoryItem] = []

			for item in response.items {
				let transactionItem = try await transaction(for: item)
				items.append(transactionItem)
			}

			return .init(cursor: response.nextCursor, items: items)

//			return try await .init(
//				cursor: response.nextCursor,
//				items: response.items.parallelMap(transaction(for:))
//			)
		}

		/*
		 public private(set) var stateVersion: Int64
		 public private(set) var epoch: Int64
		 public private(set) var round: Int64
		 public private(set) var roundTimestamp: String
		 public private(set) var transactionStatus: TransactionStatus
		 /** Bech32m-encoded hash. */
		 public private(set) var payloadHash: String?
		 /** Bech32m-encoded hash. */
		 public private(set) var intentHash: String?
		 /** String-encoded decimal representing the amount of a related fungible resource. */
		 public private(set) var feePaid: String?
		 public private(set) var affectedGlobalEntities: [String]?
		 public private(set) var confirmedAt: Date?
		 public private(set) var errorMessage: String?
		 /** Hex-encoded binary blob. */
		 public private(set) var rawHex: String?
		 public private(set) var receipt: TransactionReceipt?
		 /** A text-representation of a transaction manifest. This field will be present only for user transactions
		  and when explicitly opted-in using `manifest_instructions` flag.  */
		 public private(set) var manifestInstructions: String?
		 /** A collection of zero or more manifest classes ordered from the most specific class to the least specific one.
		  This field will be present only for user transactions.  */
		 public private(set) var manifestClasses: [ManifestClass]?
		 public private(set) var message: CoreAPI.TransactionMessage?
		 public private(set) var balanceChanges: TransactionBalanceChanges?

		 */
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
