import ComposableArchitecture
import FeaturePrelude
import GatewayAPI
import TransactionClient

// MARK: - TransactionReview
public struct TransactionReview: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let transactionManifest: TransactionManifest
		public let message: String?

		public var transactionWithLockFee: TransactionManifest?

		public var withdrawals: TransactionReviewAccounts.State? = nil
		public var dAppsUsed: TransactionReviewDappsUsed.State? = nil
		public var deposits: TransactionReviewAccounts.State? = nil
		public var proofs: TransactionReviewProofs.State? = nil
		public var networkFee: TransactionReviewNetworkFee.State? = nil

		@PresentationState
		public var customizeGuarantees: TransactionReviewGuarantees.State? = nil

		@PresentationState
		public var rawTransaction: TransactionReviewRawTransaction.State? = nil

		public var isProcessingTransaction: Bool = false

		public init(
			transactionManifest: TransactionManifest,
			message: String?,
			customizeGuarantees: TransactionReviewGuarantees.State? = nil
		) {
			self.transactionManifest = transactionManifest
			self.message = message
			self.customizeGuarantees = customizeGuarantees
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case closeTapped
		case showRawTransactionTapped

		case approveTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case withdrawals(TransactionReviewAccounts.Action)
		case deposits(TransactionReviewAccounts.Action)
		case dAppsUsed(TransactionReviewDappsUsed.Action)
		case proofs(TransactionReviewProofs.Action)
		case networkFee(TransactionReviewNetworkFee.Action)

		case customizeGuarantees(PresentationAction<TransactionReviewGuarantees.Action>)
		case rawTransaction(PresentationAction<TransactionReviewRawTransaction.Action>)
	}

	public enum InternalAction: Sendable, Equatable {
		case previewLoaded(TransactionReviewResult)
		case createTransactionReview(TransactionReview.TransactionContent)
		case signTransactionResult(TransactionResult)
		case rawTransactionCreated(String)
		case transactionPollingResult(TransactionResult)
	}

	public enum DelegateAction: Sendable, Equatable {
		case failed(TransactionFailure)
		case signedTXAndSubmittedToGateway(TransactionIntent.TXID)
		case transactionCompleted(TransactionIntent.TXID)
	}

	@Dependency(\.transactionClient) var transactionClient
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.engineToolkitClient) var engineToolkitClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.networkFee, action: /Action.child .. ChildAction.networkFee) {
				TransactionReviewNetworkFee()
			}
			.ifLet(\.deposits, action: /Action.child .. ChildAction.deposits) {
				TransactionReviewAccounts()
			}
			.ifLet(\.dAppsUsed, action: /Action.child .. ChildAction.dAppsUsed) {
				TransactionReviewDappsUsed()
			}
			.ifLet(\.withdrawals, action: /Action.child .. ChildAction.withdrawals) {
				TransactionReviewAccounts()
			}
			.ifLet(\.$customizeGuarantees, action: /Action.child .. ChildAction.customizeGuarantees) {
				TransactionReviewGuarantees()
			}
			.ifLet(\.$rawTransaction, action: /Action.child .. ChildAction.rawTransaction) {
				TransactionReviewRawTransaction()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			let manifest = state.transactionManifest
			return .run { send in
				let result = await transactionClient.getTransactionReview(.init(manifestToSign: manifest))
				await send(.internal(.previewLoaded(result)))
			}

		case .closeTapped:
			return .none

		case .showRawTransactionTapped:
			guard let transactionWithLockFee = state.transactionWithLockFee else { return .none }
			let guarantees = state.allGuarantees
			return .run { send in
				let manifest = try await addingGuarantees(to: transactionWithLockFee, guarantees: guarantees)
				await send(.internal(.rawTransactionCreated(manifest.description)))
			}

		case .approveTapped:
			guard let transactionWithLockFee = state.transactionWithLockFee else { return .none }

			state.isProcessingTransaction = true
			let guarantees = state.allGuarantees

			return .run { send in
				let manifest = try await addingGuarantees(to: transactionWithLockFee, guarantees: guarantees)

				let signRequest = SignManifestRequest(
					manifestToSign: manifest,
					makeTransactionHeaderInput: .default
				)

				await send(.internal(.signTransactionResult(
					transactionClient.signAndSubmitTransaction(signRequest)
				)))
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .withdrawals:
			return .none

		case .deposits(.delegate(.showCustomizeGuarantees)):
			guard let deposits = state.deposits else { return .none } // TODO: Handle?

			let guarantees = deposits.accounts
				.flatMap { account -> [TransactionReviewGuarantee.State] in
					account.transfers
						.filter { $0.metadata.type == .fungible }
						.map { .init(account: account.account, transfer: $0) }
				}

			state.customizeGuarantees = .init(guarantees: .init(uniqueElements: guarantees))

			return .none

		case .deposits:
			return .none

		case .dAppsUsed:
			return .none

		case .proofs:
			return .none

		case .networkFee:
			return .none

		case let .customizeGuarantees(.presented(.delegate(.applyGuarantees(guarantees)))):
			for transfer in guarantees.map(\.transfer) {
				guard let guarantee = transfer.guarantee else { continue }
				state.applyGuarantee(guarantee, transferID: transfer.id)
			}

			return .none

		case .customizeGuarantees:
			return .none

		case .rawTransaction:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .previewLoaded(.success(review)):
			let reviewedManifest = review.analyzedManifestToReview
			state.transactionWithLockFee = review.manifestIncludingLockFee
			return .run { send in
				// TODO: Determine what is the minimal information required
				let userAccounts = try await extractAccounts(reviewedManifest)

				let content = await TransactionReview.TransactionContent(
					withdrawing: try? extractWithdraws(reviewedManifest, userAccounts: userAccounts),
					dAppsUsed: try? extractUsedDapps(reviewedManifest),
					depositing: try? extractDeposits(reviewedManifest, userAccounts: userAccounts),
					presenting: try? exctractBadges(reviewedManifest),
					networkFee: .init(fee: review.transactionFeeAdded, isCongested: false)
				)
				await send(.internal(.createTransactionReview(content)))
			} catch: { _, _ in
				// TODO: Handle error
			}
		case let .createTransactionReview(content):
			state.deposits = content.deposits
			state.dAppsUsed = content.dAppsUsed
			state.withdrawals = content.withdrawals
			state.proofs = content.proofs
			state.networkFee = content.networkFee
			return .none

		case let .signTransactionResult(.success(txID)):
			return .run { send in
				await send(.delegate(.signedTXAndSubmittedToGateway(txID)))

				await send(.internal(.transactionPollingResult(
					transactionClient.getTransactionResult(txID)
				)))
			}

		case let .signTransactionResult(.failure(transactionFailure)):
			state.isProcessingTransaction = false
			return .send(.delegate(.failed(transactionFailure)))

		case let .previewLoaded(.failure(error)):
			return .send(.delegate(.failed(error)))

		case let .transactionPollingResult(.success(txID)):
			state.isProcessingTransaction = false
			return .send(.delegate(.transactionCompleted(txID)))

		case let .transactionPollingResult(.failure(error)):
			state.isProcessingTransaction = false
			return .send(.delegate(.failed(error)))

		case let .rawTransactionCreated(transaction):
			state.rawTransaction = .init(transaction: transaction)
			return .none
		}
	}

	public func addingGuarantees(to manifest: TransactionManifest, guarantees: [TransactionClient.Guarantee]) async throws -> TransactionManifest {
		guard !guarantees.isEmpty else { return manifest }
		return try await transactionClient.addGuaranteesToManifest(manifest, guarantees)
	}
}

extension TransactionReview {
	public struct TransactionContent: Sendable, Hashable {
		let withdrawals: TransactionReviewAccounts.State?
		let dAppsUsed: TransactionReviewDappsUsed.State?
		let deposits: TransactionReviewAccounts.State?
		let proofs: TransactionReviewProofs.State?
		let networkFee: TransactionReviewNetworkFee.State?
	}

	// MARK: - TransferType
	enum TransferType {
		case exact
		case estimated(instructionIndex: UInt32)
	}

	private func extractAccounts(_ manifest: AnalyzeManifestWithPreviewContextResponse) async throws -> [Account] {
		let userAccounts = try await accountsClient.getAccountsOnCurrentNetwork()
		return try manifest
			.encounteredAddresses
			.componentAddresses
			.accounts
			.map { encounteredAccount in
				let userAccount = userAccounts.first { userAccount in
					userAccount.address.address == encounteredAccount.address
				}
				if let userAccount {
					return .user(.init(address: userAccount.address, label: userAccount.displayName, appearanceID: userAccount.appearanceID))
				} else {
					return try .external(.init(componentAddress: encounteredAccount), approved: false)
				}
			}
	}

	private func exctractBadges(_ manifest: AnalyzeManifestWithPreviewContextResponse) async throws -> TransactionReviewProofs.State? {
		let dapps = try await extractDappsInfo(manifest.accountProofResources.map(\.address))
		guard !dapps.isEmpty else { return nil }

		return TransactionReviewProofs.State(dApps: .init(uniqueElements: dapps))
	}

	private func extractUsedDapps(_ manifest: AnalyzeManifestWithPreviewContextResponse) async throws -> TransactionReviewDappsUsed.State? {
		let dapps = try await extractDappsInfo(manifest.encounteredAddresses.componentAddresses.userApplications.map(\.address))
		guard !dapps.isEmpty else { return nil }

		return TransactionReviewDappsUsed.State(isExpanded: false, dApps: .init(uniqueElements: dapps))
	}

	private func extractDappsInfo(_ addresses: [String]) async throws -> [Dapp] {
		var dapps: [Dapp] = []
		for address in addresses {
			let metadata = try? await gatewayAPIClient.getEntityMetadata(address)
			dapps.append(
				Dapp(
					id: address,
					metadata: .init(name: metadata?.name ?? "Unknown", thumbnail: nil, description: metadata?.description)
				)
			)
		}
		return dapps
	}

	private func extractDeposits(
		_ manifest: AnalyzeManifestWithPreviewContextResponse,
		userAccounts: [Account]
	) async throws -> TransactionReviewAccounts.State {
		var deposits: [Account: [Transfer]] = [:]

		for deposit in manifest.accountDeposits {
			switch deposit {
			case let .exact(componentAddress, resourceSpecifier):
				try await collectTransferInfo(
					componentAddress: componentAddress,
					resourceSpecifier: resourceSpecifier,
					userAccounts: userAccounts,
					createdEntities: manifest.createdEntities,
					container: &deposits,
					type: .exact
				)
			case let .estimate(index, componentAddress, resourceSpecifier):
				try await collectTransferInfo(
					componentAddress: componentAddress,
					resourceSpecifier: resourceSpecifier,
					userAccounts: userAccounts,
					createdEntities: manifest.createdEntities,
					container: &deposits,
					type: .estimated(instructionIndex: index)
				)
			}
		}

		let reviewAccounts = deposits.map {
			TransactionReviewAccount.State(account: $0.key, transfers: .init(uniqueElements: $0.value))
		}

		let requiresGuarantees = reviewAccounts.contains { reviewAccount in
			reviewAccount.transfers.contains { transfer in
				transfer.guarantee != nil
			}
		}

		return .init(accounts: .init(uniqueElements: reviewAccounts), showCustomizeGuarantees: requiresGuarantees)
	}

	func collectTransferInfo(
		componentAddress: ComponentAddress,
		resourceSpecifier: ResourceSpecifier,
		userAccounts: [Account],
		createdEntities: CreatedEntitities?,
		container: inout [Account: [Transfer]],
		type: TransferType
	) async throws {
		let account = userAccounts.first { $0.address.address == componentAddress.address }! // TODO: Handle
		func addTransfer(_ resourceAddress: ResourceAddress, amount: BigDecimal) async throws {
			let isNewResources = createdEntities?.resourceAddresses.contains(resourceAddress) ?? false
			let metadata: GatewayAPI.EntityMetadataCollection? = await {
				guard !isNewResources else { return nil }
				return try? await gatewayAPIClient.getEntityMetadata(resourceAddress.address)
			}()

			let addressKind = try engineToolkitClient.decodeAddress(resourceAddress.address).entityType
			let action = AccountAction(
				componentAddress: componentAddress,
				resourceAddress: resourceAddress,
				amount: amount
			)

			let guarantee: TransactionClient.Guarantee? = {
				if case let .estimated(instructionIndex) = type, !isNewResources {
					return .init(amount: amount, instructionIndex: instructionIndex, resourceAddress: resourceAddress)
				}
				return nil
			}()

			let resourceMetadata = ResourceMetadata(
				name: metadata?.symbol ?? metadata?.name ?? "Unknown",
				thumbnail: nil,
				type: addressKind.resourceType
			)

			let transfer = TransactionReview.Transfer(
				action: action,
				guarantee: guarantee,
				metadata: resourceMetadata
			)

			container[account, default: []].append(transfer)
		}

		switch resourceSpecifier {
		case let .amount(resourceAddress, amount):
			try await addTransfer(resourceAddress, amount: .init(fromString: amount.value))
		case let .ids(resourceAddress, _):
			try await addTransfer(resourceAddress, amount: .init(fromString: "1"))
		}
	}

	private func extractWithdraws(
		_ manifest: AnalyzeManifestWithPreviewContextResponse,
		userAccounts: [Account]
	) async throws -> TransactionReviewAccounts.State? {
		var withdrawals: [Account: [Transfer]] = [:]

		for withdraw in manifest.accountWithdraws {
			try await collectTransferInfo(
				componentAddress: withdraw.componentAddress,
				resourceSpecifier: withdraw.resourceSpecifier,
				userAccounts: userAccounts,
				createdEntities: manifest.createdEntities,
				container: &withdraws,
				type: .exact
			)
		}

		guard !withdrawals.isEmpty else { return nil }

		let accounts = withdrawals.map {
			TransactionReviewAccount.State(account: $0.key, transfers: .init(uniqueElements: $0.value))
		}
		return .init(accounts: .init(uniqueElements: accounts), showCustomizeGuarantees: false)
	}
}

// MARK: Useful types

extension TransactionReview {
	public struct Dapp: Sendable, Identifiable, Hashable {
		public let id: AccountAddress.ID
		public let metadata: Metadata?

		init(id: AccountAddress.ID, metadata: Metadata?) {
			self.id = id
			self.metadata = metadata
		}

		public struct Metadata: Sendable, Hashable {
			public let name: String
			public let thumbnail: URL?
			public let description: String?

			public init(name: String, thumbnail: URL?, description: String?) {
				self.name = name
				self.thumbnail = thumbnail
				self.description = description
			}
		}
	}

	public enum ResourceType: Sendable, Hashable {
		case fungible
		case nonFungible
	}

	public enum Account: Sendable, Hashable {
		case user(Profile.Network.AccountForDisplay)
		case external(AccountAddress, approved: Bool)

		var address: AccountAddress {
			switch self {
			case let .user(account):
				return account.address
			case let .external(address, _):
				return address
			}
		}

		var isApproved: Bool {
			switch self {
			case .user:
				return false
			case let .external(_, approved):
				return approved
			}
		}
	}

	public struct Transfer: Sendable, Identifiable, Hashable {
		public var id: AccountAction { action }

		public let action: AccountAction
		public var guarantee: TransactionClient.Guarantee?
		public var metadata: ResourceMetadata

		public init(
			action: AccountAction,
			guarantee: TransactionClient.Guarantee? = nil,
			metadata: ResourceMetadata
		) {
			self.action = action
			self.guarantee = guarantee
			self.metadata = metadata
		}
	}

	public struct ResourceMetadata: Sendable, Hashable {
		public let name: String?
		public let thumbnail: URL?
		public var type: ResourceType?
		public var fiatAmount: BigDecimal?

		public init(
			name: String?,
			thumbnail: URL?,
			type: ResourceType? = nil,
			fiatAmount: BigDecimal? = nil
		) {
			self.name = name
			self.thumbnail = thumbnail
			self.type = type
			self.fiatAmount = fiatAmount
		}
	}
}

extension TransactionReview.State {
	public var allGuarantees: [TransactionClient.Guarantee] {
		deposits?.accounts.flatMap { $0.transfers.compactMap(\.guarantee) } ?? []
	}

	public mutating func applyGuarantee(_ updated: TransactionClient.Guarantee, transferID: TransactionReview.Transfer.ID) {
		guard let accountID = accountID(for: transferID) else { return }

		deposits?
			.accounts[id: accountID]?
			.transfers[id: transferID]?.guarantee?.amount = updated.amount
	}

	private func accountID(for transferID: TransactionReview.Transfer.ID) -> AccountAddress.ID? {
		for account in deposits?.accounts ?? [] {
			for transfer in account.transfers {
				if transfer.id == transferID {
					return account.id
				}
			}
		}
		return nil
	}
}

extension Collection where Element: Equatable {
	public func count(of element: Element) -> Int {
		var count = 0
		for e in self where e == element {
			count += 1
		}
		return count
	}
}

// MARK: - AccountAction
public struct AccountAction: Codable, Sendable, Hashable {
	public let componentAddress: ComponentAddress

	public let resourceAddress: ResourceAddress

	public let amount: BigDecimal

	public enum CodingKeys: String, CodingKey {
		case componentAddress = "component_address"
		case resourceAddress = "resource_address"
		case amount
	}
}

extension Collection<AccountAction> {
	public var groupedByAccount: [ComponentAddress: [AccountAction]] {
		.init(grouping: self, by: \.componentAddress)
	}
}

extension GatewayAPI.EntityMetadataCollection {
	var description: String? {
		self["description"]
	}

	var symbol: String? {
		self["symbol"]
	}

	var name: String? {
		self["name"]
	}

	var url: String? {
		self["url"]
	}

	subscript(key: String) -> String? {
		items.first { $0.key == key }?.value.asString
	}
}

extension EngineToolkitModels.AddressKind {
	var resourceType: TransactionReview.ResourceType? {
		switch self {
		case .fungibleResource:
			return .fungible
		case .nonFungibleResource:
			return .nonFungible
		case .package:
			return nil
		case .accountComponent:
			return nil
		case .normalComponent:
			return nil
		}
	}
}

#if DEBUG
extension TransactionReview.Dapp {
	public static let mock0 = Self(id: .deadbeef32Bytes,
								   metadata: .init(name: "Collabofi User Badge", thumbnail: nil, description: nil))

	public static let mock1 = Self(id: .deadbeef64Bytes,
								   metadata: .init(name: "Oh Babylon Founder NFT", thumbnail: nil, description: nil))

	public static let mock2 = Self(id: "deadbeef64Bytes", metadata: nil)

	public static let mock3 = Self(id: "deadbeef32Bytes", metadata: nil)
}

extension TransactionReviewAccount.State {
	public static let mockWithdraw0 = Self(account: .mockUser0, transfers: [.mock0, .mock1])

	public static let mockWithdraw1 = Self(account: .mockUser1, transfers: [.mock1, .mock3, .mock4])

	public static let mockWithdraw2 = Self(account: .mockUser0, transfers: [.mock1, .mock3])

	public static let mockDeposit1 = Self(account: .mockExternal0, transfers: [.mock0, .mock1, .mock2])

	public static let mockDeposit2 = Self(account: .mockUser0, transfers: [.mock3, .mock4])
}

extension TransactionReview.Account {
	public static let mockUser0 = user(.init(address: .mock0,
											 label: "My Main Account",
											 appearanceID: ._1))

	public static let mockUser1 = user(.init(address: .mock1,
											 label: "My Savings Account",
											 appearanceID: ._2))

	public static let mockExternal0 = external(.mock2, approved: true)
	public static let mockExternal1 = external(.mock2, approved: false)
}

extension AccountAddress {
	public static let mock0 = try! Self(address: "account_tdx_b_k591p8y440g69dlqnuzghu84e84ak088fah9u6ay440g6pzq8y4")
	public static let mock1 = try! Self(address: "account_tdx_b_e84ak088fah9u6ad6j9dlqnuz84e84ak088fau6ad6j9dlqnuzk")
	public static let mock2 = try! Self(address: "account_tdx_b_1pzq8y440g6nc4vuz0ghu84e84ak088fah9u6ad6j9dlqnuzk59")
}

extension ComponentAddress {
	public static let mock0 = Self(address: "account_tdx_b_k591p8y440g69dlqnuzghu84e84ak088fah9u6ay440g6pzq8y4")
	public static let mock1 = Self(address: "account_tdx_b_e84ak088fah9u6ad6j9dlqnuz84e84ak088fau6ad6j9dlqnuzk")
	public static let mock2 = Self(address: "account_tdx_b_1pzq8y440g6nc4vuz0ghu84e84ak088fah9u6ad6j9dlqnuzk59")
}

extension ResourceAddress {
	public static let mock0 = Self(address: "resource_tdx_b_1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq8z96qp")
	public static let mock1 = Self(address: "resource_tdx_b_1qre9sv98scqut4k9g3j6kxuvscczv0lzumefwgwhuf6qdu4c3r")
}

extension URL {
	static let mock = URL(string: "test")!
}

extension TransactionReview.Transfer {
	public static let mock0 = Self(action: .mock0,
								   guarantee: .init(amount: 1.0188, instructionIndex: 1, resourceAddress: .mock0),
								   metadata: .init(name: "TSLA",
												   thumbnail: .mock,
												   type: .fungible,
												   fiatAmount: 301.91))

	public static let mock1 = Self(action: .mock1,
								   metadata: .init(name: "XRD",
												   thumbnail: .mock,
												   type: .fungible,
												   fiatAmount: 301.91))

	public static let mock2 = Self(action: .mock2,
								   guarantee: .init(amount: 5.10, instructionIndex: 1, resourceAddress: .mock1),
								   metadata: .init(name: "PXL",
												   thumbnail: .mock,
												   type: .fungible))

	public static let mock3 = Self(action: .mock3,
								   metadata: .init(name: "PXL",
												   thumbnail: .mock,
												   type: .fungible))

	public static let mock4 = Self(action: .mock4,
								   metadata: .init(name: "Block 14F5",
												   thumbnail: .mock,
												   type: .nonFungible))

	public static var all: Set<Self> {
		[.mock0, .mock1, .mock2, .mock3, .mock4]
	}
}

extension AccountAction {
	public static let mock0 = Self(componentAddress: .mock0,
								   resourceAddress: .mock0,
								   amount: 1.0396)

	public static let mock1 = Self(componentAddress: .mock1,
								   resourceAddress: .mock1,
								   amount: 500)

	public static let mock2 = Self(componentAddress: .mock0,
								   resourceAddress: .mock1,
								   amount: 5.123)

	public static let mock3 = Self(componentAddress: .mock1,
								   resourceAddress: .mock1,
								   amount: 300)

	public static let mock4 = Self(componentAddress: .mock0,
								   resourceAddress: .mock1,
								   amount: 1)

	public static var all: Set<Self> {
		[.mock0, .mock1, .mock2, .mock3, .mock4]
	}
}
#endif
