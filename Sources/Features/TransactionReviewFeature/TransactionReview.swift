import ComposableArchitecture
import CryptoKit
import FeaturePrelude
import GatewayAPI
import SigningFeature
import TransactionClient

// MARK: - TransactionReview
public struct TransactionReview: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var displayMode: DisplayMode = .review

		public let nonce: Nonce
		public let transactionManifest: TransactionManifest
		public let message: String?
		public let signTransactionPurpose: SigningPurpose.SignTransactionPurpose

		public var transactionWithLockFee: TransactionManifest?

		public var networkID: NetworkID? = nil

		/// does not include lock fee?
		public var analyzedManifestToReview: AnalyzeTransactionExecutionResponse? = nil

		public var fee: BigDecimal
		public var feePayerSelectionAmongstCandidates: FeePayerSelectionAmongstCandidates?

		public var withdrawals: TransactionReviewAccounts.State? = nil
		public var dAppsUsed: TransactionReviewDappsUsed.State? = nil
		public var deposits: TransactionReviewAccounts.State? = nil
		public var proofs: TransactionReviewProofs.State? = nil
		public var networkFee: TransactionReviewNetworkFee.State? = nil
		public let ephemeralNotaryPrivateKey: Curve25519.Signing.PrivateKey
		public var canApproveTX: Bool = true

		@PresentationState
		public var destination: Destinations.State? = nil

		public init(
			transactionManifest: TransactionManifest,
			nonce: Nonce,
			signTransactionPurpose: SigningPurpose.SignTransactionPurpose,
			message: String?,
			feeToAdd: BigDecimal = .temporaryStandardFee, // fix me use estimate from `analyze`
			ephemeralNotaryPrivateKey: Curve25519.Signing.PrivateKey = .init(),
			customizeGuarantees: TransactionReviewGuarantees.State? = nil
		) {
			self.nonce = nonce
			self.transactionManifest = transactionManifest
			self.signTransactionPurpose = signTransactionPurpose
			self.message = message
			self.fee = feeToAdd
			if let customizeGuarantees {
				self.destination = .customizeGuarantees(customizeGuarantees)
			}
			self.ephemeralNotaryPrivateKey = ephemeralNotaryPrivateKey
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

		case destination(PresentationAction<Destinations.Action>)
	}

	public enum InternalAction: Sendable, Equatable {
		case previewLoaded(TaskResult<TransactionToReview>)
		case addedTransactionFeeToSelectedPayerResult(TaskResult<TransactionManifest>)
		case createTransactionReview(TransactionReview.TransactionContent)
		case rawTransactionCreated(String)
		case addGuaranteeToManifestResult(TaskResult<TransactionManifest>)
		case prepareForSigningResult(TaskResult<TransactionClient.PrepareForSiginingResponse>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case failed(TransactionFailure)
		case signedTXAndSubmittedToGateway(TransactionIntent.TXID)
		case transactionCompleted(TransactionIntent.TXID)
		case userDismissedTransactionStatus
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case customizeGuarantees(TransactionReviewGuarantees.State)
			case selectFeePayer(SelectFeePayer.State)
			case signing(Signing.State)
			case submitting(SubmitTransaction.State)
		}

		public enum Action: Sendable, Equatable {
			case customizeGuarantees(TransactionReviewGuarantees.Action)
			case selectFeePayer(SelectFeePayer.Action)
			case signing(Signing.Action)
			case submitting(SubmitTransaction.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.customizeGuarantees, action: /Action.customizeGuarantees) {
				TransactionReviewGuarantees()
			}
			Scope(state: /State.selectFeePayer, action: /Action.selectFeePayer) {
				SelectFeePayer()
			}
			Scope(state: /State.signing, action: /Action.signing) {
				Signing()
			}
			Scope(state: /State.submitting, action: /Action.submitting) {
				SubmitTransaction()
			}
		}
	}

	@Dependency(\.transactionClient) var transactionClient
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.engineToolkitClient) var engineToolkitClient
	@Dependency(\.continuousClock) var clock
	@Dependency(\.errorQueue) var errorQueue

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
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			let manifest = state.transactionManifest
			return .task { [feeToAdd = state.fee, nonce = state.nonce] in
				await .internal(.previewLoaded(TaskResult {
					try await transactionClient.getTransactionReview(.init(
						manifestToSign: manifest,
						nonce: nonce,
						feeToAdd: feeToAdd
					))
				}))
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
			state.canApproveTX = false

			let guarantees = state.allGuarantees

			return .task {
				await .internal(.addGuaranteeToManifestResult(
					TaskResult {
						try await addingGuarantees(
							to: transactionWithLockFee,
							guarantees: guarantees
						)
					}
				))
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .deposits(.delegate(.showCustomizeGuarantees)):
			guard let deposits = state.deposits else { return .none } // TODO: Handle?

			let guarantees = deposits.accounts
				.flatMap { account -> [TransactionReviewGuarantee.State] in
					account.transfers
						.filter { $0.metadata.type == .fungible && $0.guarantee != nil }
						.compactMap { .init(account: account.account, transfer: $0) }
				}

			state.destination = .customizeGuarantees(.init(guarantees: .init(uniqueElements: guarantees)))

			return .none

		case let .destination(.presented(.customizeGuarantees(.delegate(.applyGuarantees(guarantees))))):
			for transfer in guarantees.map(\.transfer) {
				guard let guarantee = transfer.guarantee else { continue }
				state.applyGuarantee(guarantee, transferID: transfer.id)
			}

			return .none

		case let .destination(.presented(.selectFeePayer(.delegate(.selected(selected))))):
			state.feePayerSelectionAmongstCandidates = selected
			state.destination = nil
			return .run { [transactionManifest = state.transactionManifest] send in

				await send(.internal(.addedTransactionFeeToSelectedPayerResult(
					TaskResult {
						try await transactionClient.lockFeeWithSelectedPayer(
							transactionManifest,
							selected.fee,
							selected.selected.account.address
						)
					}
				)))
			}

		case .destination(.presented(.signing(.delegate(.cancelSigning)))):
			state.destination = nil
			return cancelSigningEffect(state: &state)

		case .destination(.presented(.signing(.delegate(.failedToSign)))):
			loggerGlobal.error("Failed sign tx")
			state.destination = nil
			state.canApproveTX = true
			return .none

		case let .destination(.presented(.signing(.delegate(.finishedSigning(.signTransaction(notarizedTX, origin: _)))))):
			state.destination = .submitting(.init(notarizedTX: notarizedTX))
			return .none

		case .destination(.presented(.signing(.delegate(.finishedSigning(.signAuth(_)))))):
			state.canApproveTX = true
			assertionFailure("Did not expect to have sign auth data...")
			return .none

		case let .destination(.presented(.submitting(.delegate(.submittedButNotCompleted(txID))))):
			return .send(.delegate(.signedTXAndSubmittedToGateway(txID)))

		case
			.destination(.presented(.submitting(.delegate(.failedToSubmit)))):
			state.destination = nil
			state.canApproveTX = true
			loggerGlobal.error("Failed to submit tx")
			return .none

		case .destination(.presented(.submitting(.delegate(.failedToReceiveStatusUpdate)))):
			state.destination = nil
			loggerGlobal.error("Failed to receive status update")
			return .none

		case .destination(.presented(.submitting(.delegate(.submittedTransactionFailed)))):
			state.destination = nil
			state.canApproveTX = true
			loggerGlobal.error("Submitted TX failed")
			return .send(.delegate(.failed(.failedToSubmit)))

		case let .destination(.presented(.submitting(.delegate(.committedSuccessfully(txID))))):
			state.destination = nil
			return delayedEffect(for: .delegate(.transactionCompleted(txID)))

		case .destination(.presented(.submitting(.delegate(.dismiss)))):
			state.destination = nil
			return delayedEffect(for: .delegate(.userDismissedTransactionStatus))

		case .destination(.dismiss):
			if case .signing = state.destination {
				return cancelSigningEffect(state: &state)
			} else {
				return .none
			}

		default:
			return .none
		}
	}

	private func cancelSigningEffect(state: inout State) -> EffectTask<Action> {
		loggerGlobal.notice("Cancelled signing")
		state.canApproveTX = true
		return .none
	}

	private func review(_ state: State) -> EffectTask<Action> {
		guard let manifestPreviewToReview = state.analyzedManifestToReview else {
			assertionFailure("Bad implementation, expected `analyzedManifestToReview`")
			return .none
		}
		guard let networkID = state.networkID else {
			assertionFailure("Bad implementation, expected `networkID`")
			return .none
		}
		return review(manifestPreview: manifestPreviewToReview, feeAdded: state.fee, networkID: networkID)
	}

	private func review(
		manifestPreview manifestPreviewToReview: AnalyzeTransactionExecutionResponse,
		feeAdded: BigDecimal,
		networkID: NetworkID
	) -> EffectTask<Action> {
		.run { send in
			// TODO: Determine what is the minimal information required
			let userAccounts = try await extractUserAccounts(manifestPreviewToReview)

			let content = await TransactionReview.TransactionContent(
				withdrawals: try? extractWithdrawals(
					manifestPreviewToReview,
					userAccounts: userAccounts,
					networkID: networkID
				),
				dAppsUsed: try? extractUsedDapps(manifestPreviewToReview),
				deposits: try? extractDeposits(
					manifestPreviewToReview,
					userAccounts: userAccounts,
					networkID: networkID
				),
				proofs: try? exctractProofs(manifestPreviewToReview),
				networkFee: .init(fee: feeAdded, isCongested: false)
			)
			await send(.internal(.createTransactionReview(content)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to extract user accounts, error: \(error)")
			// FIXME: propagate/display error?
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .previewLoaded(.failure(error)):
			return .send(.delegate(.failed(TransactionFailure.failedToPrepareTXReview(.failedToGenerateTXReview(error)))))

		case let .previewLoaded(.success(preview)):
			state.networkID = preview.networkID
			switch preview.addFeeToManifestOutcome {
			case let .includesLockFee(manifestInclLockFee):
				state.feePayerSelectionAmongstCandidates = manifestInclLockFee.feePayerSelectionAmongstCandidates
				state.transactionWithLockFee = manifestInclLockFee.manifestWithLockFee
				return self.review(
					manifestPreview: preview.analyzedManifestToReview,
					feeAdded: manifestInclLockFee.feePayerSelectionAmongstCandidates.fee,
					networkID: preview.networkID
				)
			case let .excludesLockFee(excludingLockFee):
				state.analyzedManifestToReview = preview.analyzedManifestToReview
				state.destination = .selectFeePayer(.init(candidates: excludingLockFee.feePayerCandidates, fee: excludingLockFee.feeNotYetAdded))
				return .none
			}

		case let .addedTransactionFeeToSelectedPayerResult(.success(manifestWithLockFee)):
			state.transactionWithLockFee = manifestWithLockFee
			return review(state)

		case let .addedTransactionFeeToSelectedPayerResult(.failure(error)):
			loggerGlobal.error("Failed to add fee for selected payer to manifest, error: \(error)")
			// FIXME: propagate/display error?
			return .none

		case let .createTransactionReview(content):
			state.withdrawals = content.withdrawals
			state.dAppsUsed = content.dAppsUsed
			state.deposits = content.deposits
			state.proofs = content.proofs
			state.networkFee = content.networkFee
			return .none

		case let .addGuaranteeToManifestResult(.success(manifest)):
			guard let feePayerSelectionAmongstCandidates = state.feePayerSelectionAmongstCandidates else {
				assertionFailure("Expected feePayerSelectionAmongstCandidates")
				return .none
			}
			guard let networkID = state.networkID else {
				assertionFailure("Expected networkID")
				return .none
			}

			let request = TransactionClient.PrepareForSigningRequest(
				nonce: state.nonce,
				manifest: manifest,
				networkID: networkID,
				feePayer: feePayerSelectionAmongstCandidates.selected.account,
				purpose: .signTransaction(state.signTransactionPurpose),
				ephemeralNotaryPublicKey: state.ephemeralNotaryPrivateKey.publicKey
			)
			return .task {
				await .internal(.prepareForSigningResult(TaskResult {
					try await transactionClient.prepareForSigning(request)
				}))
			}

		case let .addGuaranteeToManifestResult(.failure(error)):
			loggerGlobal.error("Failed to add guarantees to manifest, error: \(error)")
			// FIXME: propagate/display error?
			return .none

		case let .rawTransactionCreated(transaction):
			state.displayMode = .raw(transaction)
			return .none
		case let .prepareForSigningResult(.success(response)):
			state.destination = .signing(.init(
				factorsLeftToSignWith: response.signingFactors,
				signingPurposeWithPayload: .signTransaction(
					ephemeralNotaryPrivateKey: state.ephemeralNotaryPrivateKey,
					response.compiledIntent,
					origin: state.signTransactionPurpose
				)
			))
			return .none
		case let .prepareForSigningResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	public func addingGuarantees(
		to manifest: TransactionManifest,
		guarantees: [TransactionClient.Guarantee]
	) async throws -> TransactionManifest {
		guard !guarantees.isEmpty else { return manifest }
		return try await transactionClient.addGuaranteesToManifest(manifest, guarantees)
	}

	func delayedEffect(
		delay: Duration = .seconds(0.3),
		for action: Action
	) -> EffectTask<Action> {
		.task {
			try await clock.sleep(for: delay)
			return action
		}
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

	private func extractUserAccounts(_ manifest: AnalyzeTransactionExecutionResponse) async throws -> [Account] {
		let userAccounts = try await accountsClient.getAccountsOnCurrentNetwork()
		return manifest
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
					return .external(encounteredAccount, approved: false)
				}
			}
	}

	private func extractUsedDapps(_ manifest: AnalyzeTransactionExecutionResponse) async throws -> TransactionReviewDappsUsed.State? {
		let components = manifest.encounteredAddresses.componentAddresses.userApplications
		let dApps = try await components.asyncMap(extractDappInfo)
		guard !dApps.isEmpty else { return nil }

		return TransactionReviewDappsUsed.State(isExpanded: true, dApps: .init(uniqueElements: Set(dApps)))
	}

	private func extractDappInfo(_ component: ComponentAddress) async throws -> LedgerEntity {
		let dAppDefinitionAddress = try await gatewayAPIClient.getDappDefinitionAddress(component)
		let metadata = try? await gatewayAPIClient.getDappMetadata(dAppDefinitionAddress)
			.validating(dAppComponent: component)

		return LedgerEntity(
			id: dAppDefinitionAddress.id,
			metadata: .init(name: metadata?.name ?? L10n.TransactionReview.unknown,
			                thumbnail: metadata?.iconURL,
			                description: metadata?.description)
		)
	}

	private func exctractProofs(_ manifest: AnalyzeTransactionExecutionResponse) async throws -> TransactionReviewProofs.State? {
		let proofs = try await manifest.accountProofResources.map(\.address).asyncMap(extractProofInfo)
		guard !proofs.isEmpty else { return nil }

		return TransactionReviewProofs.State(proofs: .init(uniqueElements: proofs))
	}

	private func extractProofInfo(_ address: String) async throws -> LedgerEntity {
		let metadata = try? await gatewayAPIClient.getEntityMetadata(address)
		return LedgerEntity(
			id: address,
			metadata: .init(name: metadata?.name ?? L10n.TransactionReview.unknown,
			                thumbnail: metadata?.iconURL,
			                description: metadata?.description)
		)
	}

	private func extractWithdrawals(
		_ manifest: AnalyzeTransactionExecutionResponse,
		userAccounts: [Account],
		networkID: NetworkID
	) async throws -> TransactionReviewAccounts.State? {
		var withdrawals: [Account: [Transfer]] = [:]

		for withdrawal in manifest.accountWithdraws {
			try await collectTransferInfo(
				componentAddress: withdrawal.componentAddress,
				resourcesQuantifer: withdrawal.resourceQuantifier,
				userAccounts: userAccounts,
				createdEntities: manifest.newlyCreated,
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
		_ manifest: AnalyzeTransactionExecutionResponse,
		userAccounts: [Account],
		networkID: NetworkID
	) async throws -> TransactionReviewAccounts.State? {
		var deposits: [Account: [Transfer]] = [:]

		for deposit in manifest.accountDeposits {
			switch deposit {
			case let .guaranteed(componentAddress, resourcesQuantifer):
				try await collectTransferInfo(
					componentAddress: componentAddress,
					resourcesQuantifer: resourcesQuantifer,
					userAccounts: userAccounts,
					createdEntities: manifest.newlyCreated,
					container: &deposits,
					networkID: networkID,
					type: .exact
				)
			case let .predicted(index, componentAddress, resourcesQuantifer):
				try await collectTransferInfo(
					componentAddress: componentAddress,
					resourcesQuantifer: resourcesQuantifer,
					userAccounts: userAccounts,
					createdEntities: manifest.newlyCreated,
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
		resourcesQuantifer: ResourceQuantifier,
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

			// let addressKind = try engineToolkitClient.decodeAddress(resourceAddress.address).entityType

			let metadata = try? await getMetadata(address: resourceAddress.address)

			let guarantee: TransactionClient.Guarantee? = {
				if case let .estimated(instructionIndex) = type, !isNewResources {
					return .init(amount: amount, instructionIndex: instructionIndex, resourceAddress: resourceAddress)
				}
				return nil
			}()

			let resourceMetadata = ResourceMetadata(
				name: metadata?.symbol ?? metadata?.name ?? L10n.TransactionReview.unknown,
				thumbnail: metadata?.iconURL,
				type: resourceAddress.resourceType
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

		switch resourcesQuantifer {
		case let .amount(resourceAddress, amount):
			fatalError()
		// try await addTransfer(resourceAddress, amount: .init(fromString: amount.value))
		case let .ids(resourceAddress, ids):
			fatalError()
			// try await addTransfer(resourceAddress, amount: BigDecimal(ids.count))
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

		public var thumbnail: TokenThumbnail.Content {
			isXRD ? .xrd : .known(metadata.thumbnail)
		}

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

extension ResourceAddress {
	var resourceType: TransactionReview.ResourceType {
		// Resource address is on of [.globalFungibleResourceManager, .globalNonFungibleResourceManager]
		if self.decodedKind == .globalFungibleResourceManager {
			return .fungible
		}
		return .nonFungible
	}
}
