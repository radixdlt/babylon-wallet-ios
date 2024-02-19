extension TransactionHistoryClient {
	public static let liveValue = TransactionHistoryClient.live()

	public static func live() -> Self {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

		@Sendable
		func resourceAddresses(for changes: GatewayAPI.TransactionBalanceChanges) throws -> [ResourceAddress] {
			try (changes.fungibleBalanceChanges.map(\.resourceAddress)
				+ changes.fungibleFeeBalanceChanges.map(\.resourceAddress)
				+ changes.nonFungibleBalanceChanges.map(\.resourceAddress)).map(ResourceAddress.init)
		}

		@Sendable
		func nonFungibleIDs(for changes: GatewayAPI.TransactionBalanceChanges) throws -> [NonFungibleGlobalId] {
			let allChanges = try changes.nonFungibleBalanceChanges.flatMap { change in
				let additions = try change.added.map { try NonFungibleGlobalId(nonFungibleGlobalId: change.resourceAddress + ":" + $0) }
				let removals = try change.added.map { try NonFungibleGlobalId(nonFungibleGlobalId: change.resourceAddress + ":" + $0) }
				return additions + removals
			}

			//			let strings = changes.nonFungibleBalanceChanges.flatMap { $0.added + $0.removed }

			for change in changes.nonFungibleBalanceChanges {
				for added in change.added {
					let id = try? NonFungibleGlobalId(nonFungibleGlobalId: change.resourceAddress + ":" + added)
					print(" •• NFT id: \(added) -> \(id?.asStr() ?? "nil")")
				}
			}

			return allChanges
		}

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
				optIns: .init(affectedGlobalEntities: true, balanceChanges: true)
//				optIns: GatewayAPI.TransactionDetailsOptIns(affectedGlobalEntities: true, manifestInstructions: true, balanceChanges: true)
			)

			let response = try await gatewayAPIClient.streamTransactions(request)

			print("• getTransactionHistory: #\(response.items.count)")

			let resourceAddresses = try Set(response.items.flatMap { try $0.balanceChanges.map(resourceAddresses) ?? [] })
			//	let resourceAddresses = ["resource_rdx1t4m25xaasa45dxs0548fdnzf76xk6m62yzltq070plmzdr4clyctuh"]

			print("• resourceAddresses: \(resourceAddresses.count)")

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

			struct MissingAmountError: Error {}

			func action(for changes: GatewayAPI.TransactionFungibleFeeBalanceChanges) throws -> TransactionHistoryItem.Action {
				let balance = try fungibleBalance(changes.resourceAddress, balanceChange: changes.balanceChange)
				return .otherBalanceChange(balance, changes.type)
			}

			func action(for changes: GatewayAPI.TransactionFungibleBalanceChanges) throws -> TransactionHistoryItem.Action {
				let balance = try fungibleBalance(changes.resourceAddress, balanceChange: changes.balanceChange)
				guard let amount = balance.amount?.amount else { throw MissingAmountError() }
				return amount.isPositive() ? .deposit(.fungible(balance)) : .withdrawal(.fungible(balance))
			}

			// Non-fungible

			let nonFungibleIDs = try Set(response.items.flatMap { try $0.balanceChanges.map(nonFungibleIDs) ?? [] })
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

			for d in nftData {
				print("• \(d.count) -<<<")
				for g in d {
					print("•• \(g.data?.name ?? "nil")")
				}
			}

			func action(for changes: GatewayAPI.TransactionNonFungibleBalanceChanges) -> TransactionHistoryItem.Action {
				fatalError()
			}

			func actions(for changes: GatewayAPI.TransactionBalanceChanges) throws -> [TransactionHistoryItem.Action] {
				try changes.fungibleBalanceChanges.map(action(for:))
					+ changes.fungibleFeeBalanceChanges.map(action(for:))
//					+ changes.nonFungibleBalanceChanges.map(action(for:))
			}

			func transaction(for info: GatewayAPI.CommittedTransactionInfo) throws -> TransactionHistoryItem? {
				guard let time = info.confirmedAt else { return nil }
				let message = info.message?.plaintext?.content.string
				let transferActions = try info.balanceChanges.map(actions(for:)) ?? []

				return .init(time: time, message: message, actions: transferActions, manifestType: .random())
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
		 /** The optional transaction message. This type is defined in the Core API as `TransactionMessage`. See the Core API documentation for more details.  */
		 public private(set) var message: AnyCodable?
		 public private(set) var balanceChanges: TransactionBalanceChanges?
		 */

		return TransactionHistoryClient(
			getTransactionHistory: getTransactionHistory
		)
	}
}

// MARK: - TransactionHistoryResponse__
/*
 (AccountAddress, String?) async throws -> [TransactionHistoryItem]

 (SpecificAddress<AccountEntityType>, Optional<String>) async throws -> TransactionHistoryResponse')
 */

public struct TransactionHistoryResponse__: Sendable, Hashable {
	public let cursor: String?
	public let items: [TransactionHistoryItem]
}

// MARK: - TransactionHistoryItem__
public struct TransactionHistoryItem__: Sendable, Hashable {
	let time: Date
	let message: String?
	let actions: [Action]
	let manifestType: ManifestType

	enum Action: Sendable, Hashable {
		case deposit(ResourceBalance)
		case withdrawal(ResourceBalance)
		case otherBalanceChange(ResourceBalance)
		case settings
	}

	enum ManifestType {
		case transfer
		case contribute
		case claim
		case depositSettings
		case other
	}
}
