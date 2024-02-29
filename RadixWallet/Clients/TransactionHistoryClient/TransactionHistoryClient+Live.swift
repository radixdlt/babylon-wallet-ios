import EngineToolkit

extension TransactionHistoryClient {
	public static let liveValue = TransactionHistoryClient.live()

	public static func live() -> Self {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

		@Sendable
		func getTransactionHistory(account: AccountAddress, period: Range<Date>, cursor: String?) async throws -> TransactionHistoryResponse {
			// FIXME: GK REMOVE THIS
//			let account = try AccountAddress(validatingAddress: "account_rdx128z7rwu87lckvjd43rnw0jh3uczefahtmfuu5y9syqrwsjpxz8hz3l")

			let account = try AccountAddress(validatingAddress: "account_rdx16x9gfj2dt82e3qvp0j775fnc06clllvf9gj86us497hyxrye656530")

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

//			for item in response.items {
//				print("• item: \(item)")
//			}

			let resourceAddresses = try Set(response.items.flatMap { try $0.balanceChanges.map(extractResourceAddresses) ?? [] })

			let resourceDetails = try await onLedgerEntitiesClient.getEntities(
				addresses: resourceAddresses.map(\.asGeneral),
				metadataKeys: .poolUnitMetadataKeys
			)

			let keyedResourceDetails = IdentifiedArray(resourceDetails.compactMap(\.resource), id: \.resourceAddress) { $1 }

			/// Returns a fungible ResourceBalance for the given resource and amount
			func fungibleBalance(_ resourceAddress: ResourceAddress, amount: RETDecimal) -> ResourceBalance.ViewState.Fungible { // FIXME: GK use full
				let title = keyedResourceDetails[id: resourceAddress]?.metadata.title
				let iconURL = keyedResourceDetails[id: resourceAddress]?.metadata.iconURL
				return .init(
					address: resourceAddress,
					icon: .token(.other(iconURL)),
					title: title,
					amount: .init(amount)
				)
			}

			// Pre-loading NFT data

			let nonFungibleIDs = try Set(response.items.flatMap { try $0.balanceChanges.map(extractAllNonFungibleIDs) ?? [] })
			let groupedNonFungibleIDs = Dictionary(grouping: nonFungibleIDs) { $0.resourceAddress() }
			let nftData = try await groupedNonFungibleIDs.parallelMap { address, ids in
				try await onLedgerEntitiesClient.getNonFungibleTokenData(.init(resource: address.asSpecific(), nonFungibleIds: ids))
			}
			var keyedNFTData: [NonFungibleGlobalId: OnLedgerEntity.NonFungibleToken] = [:]
			for nftDataArray in nftData {
				for nftDatum in nftDataArray {
					keyedNFTData[nftDatum.id] = nftDatum
				}
			}

			/// Returns a non-fungible ResourceBalance for the given global non-fungbile ID
			func nonFungibleBalance(_ id: NonFungibleGlobalId) throws -> ResourceBalance.ViewState.NonFungible { // FIXME: GK use full
				let resourceAddress: ResourceAddress = try id.resourceAddress().asSpecific()
				let resourceName = keyedResourceDetails[id: resourceAddress]?.metadata.name
				let iconURL = keyedResourceDetails[id: resourceAddress]?.metadata.iconURL
				return .init(
					id: id,
					resourceImage: iconURL,
					resourceName: resourceName,
					nonFungibleName: keyedNFTData[id]?.data?.name
				)
			}

			func transaction(for info: GatewayAPI.CommittedTransactionInfo) throws -> TransactionHistoryItem? {
				guard let time = info.confirmedAt else { return nil }
				let message = info.message?.plaintext?.content.string
				let manifestClass = info.manifestClasses?.first

				var withdrawals: [ResourceBalance.ViewState] = []
				var deposits: [ResourceBalance.ViewState] = [] // FIXME: GK use full

				if let changes = info.balanceChanges {
					for nonFungible in changes.nonFungibleBalanceChanges where nonFungible.entityAddress == account.address {
						for nonFungibleID in try extractNonFungibleIDs(.removed, from: nonFungible) {
							try withdrawals.append(.nonFungible(nonFungibleBalance(nonFungibleID)))
						}
						for nonFungibleID in try extractNonFungibleIDs(.added, from: nonFungible) {
							try deposits.append(.nonFungible(nonFungibleBalance(nonFungibleID)))
						}
					}

					for fungible in changes.fungibleBalanceChanges where fungible.entityAddress == account.address {
						let resourceAddress = try ResourceAddress(validatingAddress: fungible.resourceAddress)
						let amount = try RETDecimal(value: fungible.balanceChange)
						guard !amount.isZero() else { continue }

						// NB: The sign of the amount in the balance is made positive, negative balances are treated as withdrawals
						let balance = try fungibleBalance(resourceAddress, amount: amount.abs())

						if amount.isNegative() {
							withdrawals.append(.fungible(balance))
						} else {
							deposits.append(.fungible(balance))
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
					depositSettingsUpdated: true
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
