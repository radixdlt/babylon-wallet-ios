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
				optIns: .init(affectedGlobalEntities: true, balanceChanges: true)
//				optIns: GatewayAPI.TransactionDetailsOptIns(affectedGlobalEntities: true, manifestInstructions: true, balanceChanges: true)
			)

			let response = try await gatewayAPIClient.streamTransactions(request)

			print("• getTransactionHistory: #\(response.items.count)")

			func resourceAddresses(for changes: GatewayAPI.TransactionBalanceChanges) -> [String] {
				changes.fungibleBalanceChanges.map(\.resourceAddress)
					+ changes.fungibleFeeBalanceChanges.map(\.resourceAddress)
					+ changes.nonFungibleBalanceChanges.map(\.resourceAddress)
			}

			let addressStrings = Set(response.items.flatMap { $0.balanceChanges.map(resourceAddresses) ?? [] })
//			let addressStrings = ["resource_rdx1t4m25xaasa45dxs0548fdnzf76xk6m62yzltq070plmzdr4clyctuh"]

			print("• addressStrings: \(addressStrings.count)")

			let resourceAddresses = try addressStrings.map(ResourceAddress.init)

			let entityDetails = try await onLedgerEntitiesClient.getEntities(
				addresses: resourceAddresses.map(\.asGeneral),
				metadataKeys: .poolUnitMetadataKeys
			)

//			let keyedResourceDetails = IdentifiedArray(entityDetails.compactMap(\.resource), id: \.resourceAddress) { $1 }

			let resources = entityDetails.compactMap(\.resource)

			print("• entityDetails: \(entityDetails.count) -> \(entityDetails.compactMap(\.resource).count)")

			for entityDetail in entityDetails {
				print("  •  \(entityDetail)")
			}

			func action(for changes: GatewayAPI.TransactionFungibleFeeBalanceChanges) -> TransactionHistoryItem.Action? {
//					let resource = ResourceBalance.Fungible(address: <#T##ResourceAddress#>, title: <#T##String?#>, icon: <#T##Thumbnail.TokenContent#>, amount: <#T##ResourceBalance.Amount?#>, fallback: <#T##String?#>)
				fatalError()
			}

			func action(for changes: GatewayAPI.TransactionFungibleBalanceChanges) -> TransactionHistoryItem.Action? {
				fatalError()
			}

			func action(for changes: GatewayAPI.TransactionNonFungibleBalanceChanges) -> TransactionHistoryItem.Action? {
				fatalError()
			}

			func actions(for changes: GatewayAPI.TransactionBalanceChanges) -> [TransactionHistoryItem.Action] {
				changes.fungibleBalanceChanges.compactMap(action(for:))
					+ changes.fungibleFeeBalanceChanges.compactMap(action(for:))
					+ changes.nonFungibleBalanceChanges.compactMap(action(for:))
			}

			func transaction(for info: GatewayAPI.CommittedTransactionInfo) -> TransactionHistoryItem? {
				guard let time = info.confirmedAt else { return nil }

				// let message = info.message as? GatewayAPI.TransactionMessageView
				let actions = info.balanceChanges.map(actions(for:)) ?? []

				return .init(time: time, message: nil, actions: actions, manifestType: .random())
			}

			return .init(cursor: response.nextCursor, items: [])
//				return response.items.compactMap(transaction(for:))
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
		case deposit(RETDecimal, ResourceBalance)
		case withdrawal(RETDecimal, ResourceBalance)
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
