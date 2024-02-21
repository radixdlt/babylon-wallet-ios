import EngineToolkit

extension TransactionHistoryClient {
	public static let liveValue = TransactionHistoryClient.live()

	public static func live() -> Self {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

		@Sendable
		func getTransactionHistory(account: AccountAddress, cursor: String?) async throws -> TransactionHistoryResponse {
			let request = GatewayAPI.StreamTransactionsRequest(
				// atLedgerState: GatewayAPI.LedgerStateSelector?,
				// fromLedgerState: GatewayAPI.LedgerStateSelector?,
				cursor: cursor,
				limitPerPage: 100,
				// kindFilter: GatewayAPI.StreamTransactionsRequest.KindFilter?,
				manifestAccountsWithdrawnFromFilter: [account.address],
				manifestAccountsDepositedIntoFilter: [account.address],
				// manifestResourcesFilter: [String]?,
				// affectedGlobalEntitiesFilter: [String]?,
				// eventsFilter: [GatewayAPI.StreamTransactionsRequestEventFilterItem]?,
				// accountsWithManifestOwnerMethodCalls: [String]?,
				// accountsWithoutManifestOwnerMethodCalls: [String]?,
				// manifestClassFilter: <<error type>>,
				// order: GatewayAPI.StreamTransactionsRequest.Order?,
				optIns: .init(balanceChanges: true)
				// optIns: GatewayAPI.TransactionDetailsOptIns(affectedGlobalEntities: true, manifestInstructions: true, balanceChanges: true)
			)

			let response = try await gatewayAPIClient.streamTransactions(request)

			let resourceAddresses = try Set(response.items.flatMap { try $0.balanceChanges.map(extractResourceAddresses) ?? [] })
			//	let resourceAddresses = ["resource_rdx1t4m25xaasa45dxs0548fdnzf76xk6m62yzltq070plmzdr4clyctuh"]

			let resourceDetails = try await onLedgerEntitiesClient.getEntities(
				addresses: resourceAddresses.map(\.asGeneral),
				metadataKeys: .poolUnitMetadataKeys
			)
			let keyedResourceDetails = IdentifiedArray(resourceDetails.compactMap(\.resource), id: \.resourceAddress) { $1 }

			func fungibleBalance(_ address: String, balanceChange: String) throws -> ResourceBalance.Fungible {
				let resourceAddress = try ResourceAddress(validatingAddress: address)
				let title = keyedResourceDetails[id: resourceAddress]?.metadata.title
				let iconURL = keyedResourceDetails[id: resourceAddress]?.metadata.iconURL
				let amount = try RETDecimal(value: balanceChange)
				return try .init(
					address: resourceAddress,
					title: title,
					icon: .other(iconURL),
					amount: .init(amount.abs()),
					fallback: nil
				)
			}

			func action(for changes: GatewayAPI.TransactionFungibleBalanceChanges) throws -> TransactionHistoryItem.Action {
				struct MissingAmountError: Error {}
				let balance = try fungibleBalance(changes.resourceAddress, balanceChange: changes.balanceChange)
				guard let amount = balance.amount?.amount else { throw MissingAmountError() }
				return amount.isPositive() ? .deposit(.fungible(balance)) : .withdrawal(.fungible(balance))
			}

			// Non-fungible

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

			func nonFungibleBalance(_ id: NonFungibleGlobalId) throws -> ResourceBalance.NonFungible {
				let resourceAddress: ResourceAddress = try id.resourceAddress().asSpecific()
				let resourceName = keyedResourceDetails[id: resourceAddress]?.metadata.name
				let iconURL = keyedResourceDetails[id: resourceAddress]?.metadata.iconURL
				return .init(
					id: id,
					resourceName: resourceName,
					nonFungibleName: keyedNFTData[id]?.data?.name,
					icon: iconURL
				)
			}

			func action(for changes: GatewayAPI.TransactionNonFungibleBalanceChanges) throws -> [TransactionHistoryItem.Action] {
				let added = try extractNonFungibleIDs(.added, from: changes)
					.map { try TransactionHistoryItem.Action.deposit(.nonFungible(nonFungibleBalance($0))) }
				let removed = try extractNonFungibleIDs(.removed, from: changes)
					.map { try TransactionHistoryItem.Action.withdrawal(.nonFungible(nonFungibleBalance($0))) }

				return added + removed
			}

			func actions(for changes: GatewayAPI.TransactionBalanceChanges) throws -> [TransactionHistoryItem.Action] {
				try changes.fungibleBalanceChanges.map(action(for:))
					+ changes.nonFungibleBalanceChanges.flatMap(action(for:))
			}

			func transaction(for info: GatewayAPI.CommittedTransactionInfo) throws -> TransactionHistoryItem? {
				guard let time = info.confirmedAt else { return nil }
				let manifestClass = info.manifestClasses?.first
				let message = info.message?.plaintext?.content.string
				var actions = try info.balanceChanges.map(actions(for:)) ?? []
				if info.manifestClasses?.contains(.accountDepositSettingsUpdate) == true {
					actions.append(.settings)
				}

				for action in actions {
					print("• action: \(action)")
				}

				return .init(time: time, message: message, actions: actions, manifestClass: manifestClass)
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
