import ComposableArchitecture
import FeaturePrelude
import GatewayAPI
import TransactionClient

// MARK: - TransactionReview
public struct TransactionReview: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let transaction: P2P.FromDapp.WalletInteraction.SendTransactionItem

		public var transactionWithLockFee: TransactionManifest?

		public var withdrawing: TransactionReviewAccounts.State? = nil
		public var dAppsUsed: TransactionReviewDappsUsed.State? = nil
		public var depositing: TransactionReviewAccounts.State? = nil
		public var presenting: TransactionReviewPresenting.State? = nil
		public var networkFee: TransactionReviewNetworkFee.State? = nil

		@PresentationState
		public var customizeGuarantees: TransactionReviewGuarantees.State? = nil

		public var isSigningTX: Bool = false

		public init(
			transaction: P2P.FromDapp.WalletInteraction.SendTransactionItem,
			customizeGuarantees: TransactionReviewGuarantees.State? = nil
		) {
			self.transaction = transaction
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
		case withdrawing(TransactionReviewAccounts.Action)
		case depositing(TransactionReviewAccounts.Action)
		case dAppsUsed(TransactionReviewDappsUsed.Action)
		case presenting(TransactionReviewPresenting.Action)
		case networkFee(TransactionReviewNetworkFee.Action)

		case customizeGuarantees(PresentationAction<TransactionReviewGuarantees.Action>)
	}

	public enum InternalAction: Sendable, Equatable {
		case previewLoaded(TaskResult<TransactionToReview>)
		case createTransactionReview(TransactionReview.TransactionContent)
		case signTransactionResult(TransactionResult)
	}

	public enum DelegateAction: Sendable, Equatable {
		case failed(TransactionFailure)
		case signedTXAndSubmittedToGateway(TransactionIntent.TXID)
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
			.ifLet(\.depositing, action: /Action.child .. ChildAction.depositing) {
				TransactionReviewAccounts()
			}
			.ifLet(\.dAppsUsed, action: /Action.child .. ChildAction.dAppsUsed) {
				TransactionReviewDappsUsed()
			}
			.ifLet(\.withdrawing, action: /Action.child .. ChildAction.withdrawing) {
				TransactionReviewAccounts()
			}
			.ifLet(\.$customizeGuarantees, action: /Action.child .. ChildAction.customizeGuarantees) {
				TransactionReviewGuarantees()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			let manifest = state.transaction.transactionManifest
			return .run { send in
				let result = await TaskResult {
					try await transactionClient.getTransactionReview(.init(manifestToSign: manifest))
				}

				await send(.internal(.previewLoaded(result)))
			}

		case .closeTapped:
			return .none

		case .showRawTransactionTapped:
			guard let transactionWithLockFee = state.transactionWithLockFee else { return .none }
			let guarantees = state.allGuarantees
			return .fireAndForget {
				let manifest = try await addingGuarantees(to: transactionWithLockFee, guarantees: guarantees)
				print("MANIFEST after:\n", manifest)
			}

		case .approveTapped:
			guard let transactionWithLockFee = state.transactionWithLockFee else { return .none }

			state.isSigningTX = true
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
		case .withdrawing:
			return .none

		case .depositing(.delegate(.showCustomizeGuarantees)):

//			let depositing = TransactionReviewAccounts.State(accounts: [.mockDeposit1, .mockDeposit2], showCustomizeGuarantees: true)

			guard let depositing = state.depositing else { return .none } // TODO: Handle?

			let allTokens = depositing.accounts.flatMap { $0.transfers.map(\.action.resourceAddress) }

			let guarantees = depositing.accounts
				.flatMap { account -> [TransactionReviewGuarantee.State] in
					account.transfers
						.filter { $0.metadata.type == .fungible }
						.map { .init(account: account.account,
						             showAccount: allTokens.count(of: $0.action.resourceAddress) > 1,
						             transfer: $0)
						}
				}

			state.customizeGuarantees = .init(guarantees: .init(uniqueElements: guarantees))

			return .none

		case .depositing:
			return .none

		case .dAppsUsed:
			return .none

		case .presenting:
			return .none

		case .networkFee:
			return .none

		case let .customizeGuarantees(.presented(.delegate(.dismiss(apply: apply)))):
			if apply, let guarantees = state.customizeGuarantees?.guarantees {
				for transfer in guarantees.map(\.transfer) {
					guard let guarantee = transfer.guarantee else { continue }
					state.applyGuarantee(guarantee, transferID: transfer.id)
				}
			}
			state.customizeGuarantees = nil
			return .none

		case .customizeGuarantees:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .previewLoaded(.success(review)):
			let reviewedManifest = review.analizedManifestToReview
			state.transactionWithLockFee = review.manifestIncludingLockFee
			return .run { send in
				// TODO: Determine what is the minimal information required
				let userAccounts = try await extractAccounts(reviewedManifest)

				let content = await TransactionReview.TransactionContent(
					withdrawing: try? extractWithdraws(reviewedManifest.accountWithdraws, userAccounts: userAccounts),
					dAppsUsed: try? extractUsedDapps(reviewedManifest),
					depositing: try? extractDeposits(reviewedManifest.accountDeposits, userAccounts: userAccounts),
					presenting: try? exctractBadges(reviewedManifest),
					networkFee: .init(fee: review.transactionFeeAdded, isCongested: false)
				)
				await send(.internal(.createTransactionReview(content)))
			} catch: { _, _ in
				// TODO: Handle error
			}
		case let .createTransactionReview(content):
			state.depositing = content.depositing
			state.dAppsUsed = content.dAppsUsed
			state.withdrawing = content.withdrawing
			state.presenting = content.presenting
			state.networkFee = content.networkFee
			return .none

		case let .signTransactionResult(.success(txID)):
			state.isSigningTX = false
			return .send(.delegate(.signedTXAndSubmittedToGateway(txID)))

		case let .signTransactionResult(.failure(transactionFailure)):
			state.isSigningTX = false
			return .send(.delegate(.failed(transactionFailure)))

		case let .previewLoaded(.failure(error)):
			return .send(.delegate(.failed(.failedToPrepareForTXSigning(.failedToParseTXItIsProbablyInvalid))))
		}
	}

	public func addingGuarantees(to manifest: TransactionManifest, guarantees: [TransactionClient.Guarantee]) async throws -> TransactionManifest {
		guard !guarantees.isEmpty else { return manifest }
		return try await transactionClient.addGuaranteesToManifest(manifest, guarantees)
	}
}

extension TransactionReview {
	public struct TransactionContent: Sendable, Hashable {
		let withdrawing: TransactionReviewAccounts.State?
		let dAppsUsed: TransactionReviewDappsUsed.State?
		let depositing: TransactionReviewAccounts.State?
		let presenting: TransactionReviewPresenting.State?
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

	private func exctractBadges(_ manifest: AnalyzeManifestWithPreviewContextResponse) async throws -> TransactionReviewPresenting.State? {
		let dapps = try await extractDappsInfo(manifest.accountProofResources.map(\.address))
		guard !dapps.isEmpty else { return nil }

		return TransactionReviewPresenting.State(dApps: .init(uniqueElements: dapps))
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

	private func extractDeposits(_ accountDeposits: [AccountDeposit], userAccounts: [Account]) async throws -> TransactionReviewAccounts.State {
		var deposits: [Account: [Transfer]] = [:]

		for deposit in accountDeposits {
			switch deposit {
			case let .exact(componentAddress, resourceSpecifier):
				try await collectTransferInfo(componentAddress: componentAddress, resourceSpecifier: resourceSpecifier, userAccounts: userAccounts, container: &deposits, type: .exact)
			case let .estimate(index, componentAddress, resourceSpecifier):
				try await collectTransferInfo(componentAddress: componentAddress, resourceSpecifier: resourceSpecifier, userAccounts: userAccounts, container: &deposits, type: .estimated(instructionIndex: index))
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
		container: inout [Account: [Transfer]],
		type: TransferType
	) async throws {
		let account = userAccounts.first { $0.address.address == componentAddress.address }! // TODO: Handle
		func addTransfer(_ resourceAddress: ResourceAddress, amount: BigDecimal) async throws {
			let metadata = try? await gatewayAPIClient.getEntityMetadata(resourceAddress.address)
			let addressKind = try engineToolkitClient.decodeAddress(resourceAddress.address).entityType
			let action = AccountAction(
				componentAddress: componentAddress,
				resourceAddress: resourceAddress,
				amount: amount
			)

			let guarantee: TransactionClient.Guarantee? = {
				if case let .estimated(instructionIndex) = type, addressKind == .fungibleResource {
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
		_ accountWithdraws: [AccountWithdraw],
		userAccounts: [Account]
	) async throws -> TransactionReviewAccounts.State? {
		var withdraws: [Account: [Transfer]] = [:]

		for withdraw in accountWithdraws {
			try await collectTransferInfo(componentAddress: withdraw.componentAddress, resourceSpecifier: withdraw.resourceSpecifier, userAccounts: userAccounts, container: &withdraws, type: .exact)
		}

		guard !withdraws.isEmpty else { return nil }

		let accounts = withdraws.map {
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
		depositing?.accounts.flatMap { $0.transfers.compactMap(\.guarantee) } ?? []
	}

	public mutating func applyGuarantee(_ updated: TransactionClient.Guarantee, transferID: TransactionReview.Transfer.ID) {
		guard let accountID = accountID(for: transferID) else { return }

		depositing?
			.accounts[id: accountID]?
			.transfers[id: transferID]?.guarantee?.amount = updated.amount
	}

	private func accountID(for transferID: TransactionReview.Transfer.ID) -> AccountAddress.ID? {
		for account in depositing?.accounts ?? [] {
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

// extension TransactionReview.State {
//	public static let mock0 = Self(transaction: .previewValue,
//	                               withdrawing: .init(accounts: [.mockWithdraw0], showCustomizeGuarantees: false),
//	                               dAppsUsed: .init(isExpanded: false, dApps: []),
//	                               depositing: .init(accounts: [.mockDeposit1], showCustomizeGuarantees: true),
//	                               presenting: .init(dApps: [.mock1, .mock0]),
//	                               networkFee: .init(fee: 0.1, isCongested: false))
//
//	public static let mock1 = Self(transaction: .previewValue,
//	                               withdrawing: .init(accounts: [.mockWithdraw0, .mockWithdraw1], showCustomizeGuarantees: false),
//	                               dAppsUsed: .init(isExpanded: true, dApps: [.mock3, .mock2, .mock1]),
//	                               depositing: .init(accounts: [.mockDeposit2], showCustomizeGuarantees: true),
//	                               presenting: .init(dApps: [.mock1, .mock0]),
//	                               networkFee: .init(fee: 0.2, isCongested: true))
// }

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
