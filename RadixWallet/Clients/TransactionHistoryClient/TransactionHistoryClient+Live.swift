import EngineToolkit

extension SpecificAddress {
	public func networkID() throws -> NetworkID {
		try .init(intoEngine().networkId())
	}
}

extension TransactionHistoryClient {
	public static let liveValue = TransactionHistoryClient.live()

	public static func live() -> Self {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

		@Sendable
		func getTransactionHistory(account: AccountAddress, period: Range<Date>, cursor: String?) async throws -> TransactionHistoryResponse {
			let networkID = try account.networkID()

			// FIXME: GK REMOVE THIS
			let account = try AccountAddress(validatingAddress: "account_rdx128z7rwu87lckvjd43rnw0jh3uczefahtmfuu5y9syqrwsjpxz8hz3l")

//			let account = try AccountAddress(validatingAddress: "account_rdx16x9gfj2dt82e3qvp0j775fnc06clllvf9gj86us497hyxrye656530")

			let request = GatewayAPI.StreamTransactionsRequest(
				atLedgerState: .init(timestamp: period.upperBound),
				fromLedgerState: .init(timestamp: period.lowerBound),
				cursor: cursor,
				limitPerPage: 100,
				// kindFilter: GatewayAPI.StreamTransactionsRequest.KindFilter?,
//				manifestAccountsWithdrawnFromFilter: [account.address],
//				manifestAccountsDepositedIntoFilter: [account.address],
				// manifestResourcesFilter: [String]?,
				affectedGlobalEntitiesFilter: [account.address],
				// eventsFilter: [GatewayAPI.StreamTransactionsRequestEventFilterItem]?,
				// accountsWithManifestOwnerMethodCalls: [String]?,
				// accountsWithoutManifestOwnerMethodCalls: [String]?,
				// manifestClassFilter: <<error type>>,
				// order: GatewayAPI.StreamTransactionsRequest.Order?,
				optIns: .init(balanceChanges: true)
				// optIns: GatewayAPI.TransactionDetailsOptIns(affectedGlobalEntities: true, manifestInstructions: true, balanceChanges: true)
			)

			let response = try await gatewayAPIClient.streamTransactions(request)

			// Pre-loading the details for all the resources involved

			print("• RESPONSE: \(period.lowerBound.formatted(date: .abbreviated, time: .omitted)) -> \(period.upperBound.formatted(date: .abbreviated, time: .omitted)) \(response.items.count)")

			let resourceAddresses = try Set(response.items.flatMap { try $0.balanceChanges.map(extractResourceAddresses) ?? [] })

			let resourceDetails = try await onLedgerEntitiesClient.getEntities(
				addresses: resourceAddresses.map(\.asGeneral),
				metadataKeys: .resourceMetadataKeys
			)

			let keyedResources = IdentifiedArray(uniqueElements: resourceDetails.compactMap(\.resource))

			// Thrown if a resource or nonFungibleToken that we loaded is not present, should never happen
			struct ProgrammerError: Error {}

			/// Returns a fungible ResourceBalance for the given resource and amount
			func fungibleResource(_ address: ResourceAddress, amount: RETDecimal) throws -> ResourceBalance {
				guard let resource = keyedResources[id: address] else {
					throw ProgrammerError()
				}

				let details = ResourceBalance.Fungible(
					isXRD: address.isXRD(on: networkID),
					amount: amount // FIXME: GK? guarantee is not relevant here, right?
				)

				return .init(resource: resource, details: .fungible(details))
			}

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

			/// Returns a non-fungible ResourceBalance for the given global non-fungbile ID
			func nonFungibleResource(_ id: NonFungibleGlobalId) throws -> ResourceBalance {
				let resourceAddress: ResourceAddress = try id.resourceAddress().asSpecific()

				guard let resource = keyedResources[id: resourceAddress], let token = keyedNonFungibleTokens[id: id] else {
					throw ProgrammerError()
				}

				let details = try ResourceBalance.NonFungible(
					resourceAddress: resourceAddress,
					nftID: id.localId(),
					nftData: token.data
				)

				return ResourceBalance(resource: resource, details: .nonFungible(details))
			}

			let dateformatter = ISO8601DateFormatter()
			print("• \(dateformatter.formatOptions.contains(.withFractionalSeconds))")
			dateformatter.formatOptions.insert(.withFractionalSeconds)

			func transaction(for info: GatewayAPI.CommittedTransactionInfo) throws -> TransactionHistoryItem? {
				guard let time = dateformatter.date(from: info.roundTimestamp) else {
					struct CorruptTimestamp: Error { let roundTimestamd: String }
					throw CorruptTimestamp(roundTimestamd: info.roundTimestamp)
				}
				let message = info.message?.plaintext?.content.string
				let manifestClass = info.manifestClasses?.first

				var withdrawals: [ResourceBalance] = []
				var deposits: [ResourceBalance] = []

				if let changes = info.balanceChanges {
					for nonFungible in changes.nonFungibleBalanceChanges where nonFungible.entityAddress == account.address {
						for nonFungibleID in try extractNonFungibleIDs(.removed, from: nonFungible) {
							try withdrawals.append(nonFungibleResource(nonFungibleID))
						}
						for nonFungibleID in try extractNonFungibleIDs(.added, from: nonFungible) {
							try deposits.append(nonFungibleResource(nonFungibleID))
						}
					}

					for fungible in changes.fungibleBalanceChanges where fungible.entityAddress == account.address {
						let resourceAddress = try ResourceAddress(validatingAddress: fungible.resourceAddress)
						let amount = try RETDecimal(value: fungible.balanceChange)
						guard !amount.isZero() else { continue }

						// NB: The sign of the amount in the balance is made positive, negative balances are treated as withdrawals
						let resource = try fungibleResource(resourceAddress, amount: amount.abs())

						if amount.isNegative() {
							withdrawals.append(resource)
						} else {
							deposits.append(resource)
						}
					}
				}

				withdrawals.sort(by: >)
				deposits.sort(by: >)

				return .init(
					time: time,
					message: message,
					manifestClass: manifestClass,
					withdrawals: withdrawals,
					deposits: deposits,
					depositSettingsUpdated: info.manifestClasses?.contains(.accountDepositSettingsUpdate) == true
				)
			}

			return try .init(
				cursor: response.nextCursor,
				items: response.items.compactMap(transaction(for:))
			)
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
