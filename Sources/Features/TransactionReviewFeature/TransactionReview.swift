import ComposableArchitecture
import FeaturePrelude
import GatewayAPI
import TransactionClient

// MARK: - TransactionReview
public struct TransactionReview: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var displayMode: DisplayMode = .review

		public let transactionManifest: TransactionManifest
		public let message: String?

		public var transactionWithLockFee: TransactionManifest?

		public var networkID: NetworkID? = nil
		public var withdrawals: TransactionReviewAccounts.State? = nil
		public var dAppsUsed: TransactionReviewDappsUsed.State? = nil
		public var deposits: TransactionReviewAccounts.State? = nil
		public var proofs: TransactionReviewProofs.State? = nil
		public var networkFee: TransactionReviewNetworkFee.State? = nil

		@PresentationState
		public var customizeGuarantees: TransactionReviewGuarantees.State? = nil

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

		public enum DisplayMode: Sendable, Hashable {
			case review
			case raw(String)

			var rawTransaction: String? {
				guard case let .raw(transaction) = self else { return nil }
				return transaction
			}
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
			.ifLet(\.proofs, action: /Action.child .. ChildAction.proofs) {
				TransactionReviewProofs()
			}
			.ifLet(\.$customizeGuarantees, action: /Action.child .. ChildAction.customizeGuarantees) {
				TransactionReviewGuarantees()
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
			switch state.displayMode {
			case .review:
				guard let transactionWithLockFee = state.transactionWithLockFee, let networkID = state.networkID else { return .none }
				let guarantees = state.allGuarantees
				return .run { send in
					let manifest = try await addingGuarantees(to: transactionWithLockFee, guarantees: guarantees)
					let rawTransaction = try manifest.toString(preamble: "", networkID: networkID)
					await send(.internal(.rawTransactionCreated(rawTransaction)))
				} catch: { _, _ in
					// TODO: Handle error?
				}

			case .raw:
				state.displayMode = .review
				return .none
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
						.filter { $0.metadata.type == .fungible && $0.guarantee != nil }
						.compactMap { .init(account: account.account, transfer: $0) }
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
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .previewLoaded(.success(review)):
			let reviewedManifest = review.analyzedManifestToReview
			state.transactionWithLockFee = review.manifestIncludingLockFee
			state.networkID = review.networkID
			return .run { send in
				// TODO: Determine what is the minimal information required
				let userAccounts = try await extractUserAccounts(reviewedManifest)

				let content = await TransactionReview.TransactionContent(
					withdrawals: try? extractWithdrawals(reviewedManifest, userAccounts: userAccounts, networkID: review.networkID),
					dAppsUsed: try? extractUsedDapps(reviewedManifest),
					deposits: try? extractDeposits(reviewedManifest, userAccounts: userAccounts, networkID: review.networkID),
					proofs: try? exctractProofs(reviewedManifest),
					networkFee: .init(fee: review.transactionFeeAdded, isCongested: false)
				)
				await send(.internal(.createTransactionReview(content)))
			} catch: { _, _ in
				// TODO: Handle error
			}
		case let .createTransactionReview(content):
			state.withdrawals = content.withdrawals
			state.dAppsUsed = content.dAppsUsed
			state.deposits = content.deposits
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
			state.displayMode = .raw(transaction)
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

	private func extractUserAccounts(_ manifest: AnalyzeManifestWithPreviewContextResponse) async throws -> [Account] {
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

	private func extractUsedDapps(_ manifest: AnalyzeManifestWithPreviewContextResponse) async throws -> TransactionReviewDappsUsed.State? {
		let addresses = manifest.encounteredAddresses.componentAddresses.userApplications.map(\.address)
		let dApps = try await addresses.asyncMap(extractDappInfo)
		guard !dApps.isEmpty else { return nil }

		return TransactionReviewDappsUsed.State(isExpanded: true, dApps: .init(uniqueElements: dApps))
	}

	private func extractDappInfo(_ address: String) async throws -> LedgerEntity {
		let metadata = try? await gatewayAPIClient.getDappDefinition(address)
		return LedgerEntity(
			id: address,
			metadata: .init(name: metadata?.name ?? L10n.TransactionReview.unknown,
			                thumbnail: nil,
			                description: metadata?.description)
		)
	}

	private func exctractProofs(_ manifest: AnalyzeManifestWithPreviewContextResponse) async throws -> TransactionReviewProofs.State? {
		let proofs = try await manifest.accountProofResources.map(\.address).asyncMap(extractProofInfo)
		guard !proofs.isEmpty else { return nil }

		return TransactionReviewProofs.State(proofs: .init(uniqueElements: proofs))
	}

	private func extractProofInfo(_ address: String) async throws -> LedgerEntity {
		let metadata = try? await gatewayAPIClient.getEntityMetadata(address)
		return LedgerEntity(
			id: address,
			metadata: .init(name: metadata?.name ?? L10n.TransactionReview.unknown,
			                thumbnail: nil,
			                description: metadata?.description)
		)
	}

	private func extractWithdrawals(
		_ manifest: AnalyzeManifestWithPreviewContextResponse,
		userAccounts: [Account],
		networkID: NetworkID
	) async throws -> TransactionReviewAccounts.State? {
		var withdrawals: [Account: [Transfer]] = [:]

		for withdrawal in manifest.accountWithdraws {
			try await collectTransferInfo(
				componentAddress: withdrawal.componentAddress,
				resourceSpecifier: withdrawal.resourceSpecifier,
				userAccounts: userAccounts,
				createdEntities: manifest.createdEntities,
				container: &withdrawals,
				networkID: networkID,
				type: .exact
			)
		}

		guard !withdrawals.isEmpty else { return nil }

		let accounts = withdrawals.map {
			TransactionReviewAccount.State(account: $0.key, transfers: .init(uniqueElements: $0.value))
		}
		return .init(accounts: .init(uniqueElements: accounts), showCustomizeGuarantees: false)
	}

	private func extractDeposits(
		_ manifest: AnalyzeManifestWithPreviewContextResponse,
		userAccounts: [Account],
		networkID: NetworkID
	) async throws -> TransactionReviewAccounts.State? {
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
					networkID: networkID,
					type: .exact
				)
			case let .estimate(index, componentAddress, resourceSpecifier):
				try await collectTransferInfo(
					componentAddress: componentAddress,
					resourceSpecifier: resourceSpecifier,
					userAccounts: userAccounts,
					createdEntities: manifest.createdEntities,
					container: &deposits,
					networkID: networkID,
					type: .estimated(instructionIndex: index)
				)
			}
		}

		let reviewAccounts = deposits
			.filter { !$0.value.isEmpty }
			.map { TransactionReviewAccount.State(account: $0.key, transfers: .init(uniqueElements: $0.value)) }

		guard !reviewAccounts.isEmpty else { return nil }

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
		networkID: NetworkID,
		type: TransferType
	) async throws {
		let account = userAccounts.first { $0.address.address == componentAddress.address }! // TODO: Handle
		func addTransfer(_ resourceAddress: ResourceAddress, amount: BigDecimal) async throws {
			let isNewResources = createdEntities?.resourceAddresses.contains(resourceAddress) ?? false

			func getMetadata(address: String) async throws -> GatewayAPI.EntityMetadataCollection? {
				guard !isNewResources else { return nil }
				return try await gatewayAPIClient.getEntityMetadata(address)
			}

			let addressKind = try engineToolkitClient.decodeAddress(resourceAddress.address).entityType

			let metadata = try? await getMetadata(address: resourceAddress.address)

			let guarantee: TransactionClient.Guarantee? = {
				if case let .estimated(instructionIndex) = type, !isNewResources {
					return .init(amount: amount, instructionIndex: instructionIndex, resourceAddress: resourceAddress)
				}
				return nil
			}()

			let resourceMetadata = ResourceMetadata(
				name: metadata?.symbol ?? metadata?.name ?? L10n.TransactionReview.unknown,
				thumbnail: nil,
				type: addressKind.resourceType
			)

			let transfer = try TransactionReview.Transfer(
				amount: amount,
				resourceAddress: resourceAddress,
				isXRD: engineToolkitClient.isXRD(resource: resourceAddress, on: networkID),
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
}

// MARK: Useful types

extension TransactionReview {
	public struct LedgerEntity: Sendable, Identifiable, Hashable {
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
		public let id: UUID = .init()

		public let amount: BigDecimal
		public let resourceAddress: ResourceAddress
		public let isXRD: Bool

		public var guarantee: TransactionClient.Guarantee?
		public var metadata: ResourceMetadata

		public init(
			amount: BigDecimal,
			resourceAddress: ResourceAddress,
			isXRD: Bool,
			guarantee: TransactionClient.Guarantee? = nil,
			metadata: ResourceMetadata
		) {
			self.amount = amount
			self.resourceAddress = resourceAddress
			self.isXRD = isXRD
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
			.transfers[id: transferID]?
			.guarantee?
			.amount = updated.amount
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
		case .secp256k1VirtualAccountComponent:
			return nil
		case .ed25519VirtualAccountComponent:
			return nil
		case .secp256k1VirtualIdentityComponent:
			return nil
		case .ed25519VirtualIdentityComponent:
			return nil
		case .identityComponent:
			return nil
		case .epochManager:
			return nil
		case .validator:
			return nil
		case .clock:
			return nil
		case .accessControllerComponent:
			return nil
		}
	}
}
