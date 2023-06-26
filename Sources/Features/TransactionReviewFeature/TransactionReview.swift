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
		public var analyzedManifestToReview: AnalyzeManifestWithPreviewContextResponse? = nil

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
			feeToAdd: BigDecimal = .temporaryStandardFee, // FIXME: use estimate from `analyze`
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
			case dApp(SimpleDappDetails.State)
		}

		public enum Action: Sendable, Equatable {
			case customizeGuarantees(TransactionReviewGuarantees.Action)
			case selectFeePayer(SelectFeePayer.Action)
			case signing(Signing.Action)
			case submitting(SubmitTransaction.Action)
			case dApp(SimpleDappDetails.Action)
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
			Scope(state: /State.dApp, action: /Action.dApp) {
				SimpleDappDetails()
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

			return .task { [guarantees = state.allGuarantees] in
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
		case let .dAppsUsed(.delegate(.openDapp(id))):
			state.destination = .dApp(.init(dAppID: id))
			return .none

		case .deposits(.delegate(.showCustomizeGuarantees)):
			guard let deposits = state.deposits else { return .none } // TODO: Handle?

			let guarantees = deposits.accounts
				.flatMap { account -> [TransactionReviewGuarantee.State] in
					account.transfers
						.compactMap(\.fungible)
						.filter { $0.guarantee != nil }
						.compactMap { .init(account: account.account, transfer: $0) }
				}

			state.destination = .customizeGuarantees(.init(guarantees: .init(uniqueElements: guarantees)))

			return .none

		case let .destination(.presented(presentedAction)):
			return reduce(into: &state, presentedAction: presentedAction)

		case .destination(.dismiss):
			if case .signing = state.destination {
				return cancelSigningEffect(state: &state)
			} else if case .submitting = state.destination {
				// This is used when tapping outside the Submitting sheet, no need to set destination to nil
				return delayedEffect(for: .delegate(.userDismissedTransactionStatus))
			}

			return .none

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destinations.Action) -> EffectTask<Action> {
		switch presentedAction {
		case let .customizeGuarantees(.delegate(.applyGuarantees(guarantees))):
			for transfer in guarantees.map(\.transfer) {
				guard let guarantee = transfer.guarantee else { continue }
				state.applyGuarantee(guarantee, transferID: transfer.id)
			}

			return .none
		case .customizeGuarantees:
			return .none

		case let .selectFeePayer(.delegate(.selected(selected))):
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

		case .selectFeePayer:
			return .none

		case .signing(.delegate(.cancelSigning)):
			state.destination = nil
			return cancelSigningEffect(state: &state)

		case .signing(.delegate(.failedToSign)):
			loggerGlobal.error("Failed sign tx")
			state.destination = nil
			state.canApproveTX = true
			return .none

		case let .signing(.delegate(.finishedSigning(.signTransaction(notarizedTX, origin: _)))):
			state.destination = .submitting(.init(notarizedTX: notarizedTX))
			return .none

		case .signing(.delegate(.finishedSigning(.signAuth(_)))):
			state.canApproveTX = true
			assertionFailure("Did not expect to have sign auth data...")
			return .none

		case .signing:
			return .none

		case let .submitting(.delegate(.submittedButNotCompleted(txID))):
			return .send(.delegate(.signedTXAndSubmittedToGateway(txID)))

		case .submitting(.delegate(.failedToSubmit)):
			state.destination = nil
			state.canApproveTX = true
			loggerGlobal.error("Failed to submit tx")
			return .none

		case .submitting(.delegate(.failedToReceiveStatusUpdate)):
			state.destination = nil
			loggerGlobal.error("Failed to receive status update")
			return .none

		case .submitting(.delegate(.submittedTransactionFailed)):
			state.destination = nil
			state.canApproveTX = true
			loggerGlobal.error("Submitted TX failed")
			return .send(.delegate(.failed(.failedToSubmit)))

		case let .submitting(.delegate(.committedSuccessfully(txID))):
			state.destination = nil
			return delayedEffect(for: .delegate(.transactionCompleted(txID)))

		case .submitting(.delegate(.manuallyDismiss)):
			// This is used when the close button is pressed, we have to manually
			state.destination = nil
			return delayedEffect(for: .delegate(.userDismissedTransactionStatus))

		case .submitting:
			return .none

		case .dApp:
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
		manifestPreview manifestPreviewToReview: AnalyzeManifestWithPreviewContextResponse,
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
				proofs: exctractProofs(manifestPreviewToReview),
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
		let components = manifest.encounteredAddresses.componentAddresses.userApplications
		let dApps = try await components.asyncMap(extractDappInfo)
		guard !dApps.isEmpty else { return nil }

		return TransactionReviewDappsUsed.State(isExpanded: true, dApps: .init(uniqueElements: Set(dApps)))
	}

	private func extractDappInfo(_ component: ComponentAddress) async throws -> DappEntity {
		let dAppDefinitionAddress = try await gatewayAPIClient.getDappDefinitionAddress(component)
		let metadata = try? await gatewayAPIClient.getDappMetadata(dAppDefinitionAddress)
			.validating(dAppComponent: component)

		return DappEntity(
			id: dAppDefinitionAddress,
			metadata: .init(metadata: metadata)
		)
	}

	private func exctractProofs(_ manifest: AnalyzeManifestWithPreviewContextResponse) async -> TransactionReviewProofs.State? {
		let proofs = await manifest.accountProofResources.asyncMap(extractProofInfo)
		guard !proofs.isEmpty else { return nil }

		return TransactionReviewProofs.State(proofs: .init(uniqueElements: proofs))
	}

	private func extractProofInfo(_ address: ResourceAddress) async -> ProofEntity {
		await ProofEntity(
			id: address,
			metadata: .init(metadata: try? gatewayAPIClient.getEntityMetadata(address.address))
		)
	}

	private func extractWithdrawals(
		_ manifest: AnalyzeManifestWithPreviewContextResponse,
		userAccounts: [Account],
		networkID: NetworkID
	) async throws -> TransactionReviewAccounts.State? {
		var withdrawals: [Account: [Transfer]] = [:]

		for withdrawal in manifest.accountWithdraws {
			let account = try userAccounts.account(for: withdrawal.componentAddress)

			let transfers = try await transferInfo(
				resourceSpecifier: withdrawal.resourceSpecifier,
				createdEntities: manifest.createdEntities,
				networkID: networkID,
				type: .exact
			)

			withdrawals[account, default: []].append(contentsOf: transfers)
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
			let account = try userAccounts.account(for: deposit.componentAddress)

			let transfers = try await transferInfo(
				resourceSpecifier: deposit.resourceSpecifier,
				createdEntities: manifest.createdEntities,
				networkID: networkID,
				type: deposit.transferType
			)

			deposits[account, default: []].append(contentsOf: transfers)
		}

		let reviewAccounts = deposits
			.filter { !$0.value.isEmpty }
			.map { TransactionReviewAccount.State(account: $0.key, transfers: .init(uniqueElements: $0.value)) }

		guard !reviewAccounts.isEmpty else { return nil }

		let requiresGuarantees = reviewAccounts.contains { reviewAccount in
			reviewAccount.transfers.contains { $0.fungible?.guarantee != nil }
		}

		return .init(accounts: .init(uniqueElements: reviewAccounts), showCustomizeGuarantees: requiresGuarantees)
	}

	func transferInfo(
		resourceSpecifier: ResourceSpecifier,
		createdEntities: CreatedEntitities?,
		networkID: NetworkID,
		type: TransferType
	) async throws -> [Transfer] {
		let resourceAddress = resourceSpecifier.resourceAddress
		let isNew = createdEntities?.resourceAddresses.contains(resourceAddress) == true
		let metadata = isNew ? nil : try? await gatewayAPIClient.getEntityMetadata(resourceAddress.address)
		let addressKind = try engineToolkitClient.decodeAddress(resourceAddress.address).entityType

		switch (resourceSpecifier, addressKind) {
		case (let .amount(_, decimalAmount), .fungibleResource):
			let amount = try BigDecimal(fromString: decimalAmount.value)

			func guarantee() -> TransactionClient.Guarantee? {
				guard !isNew, case let .estimated(instructionIndex) = type else { return nil }
				return .init(amount: amount, instructionIndex: instructionIndex, resourceAddress: resourceAddress)
			}

			return [.fungible(.init(
				amount: amount,
				name: metadata?.name,
				symbol: metadata?.symbol,
				thumbnail: metadata?.iconURL,
				isXRD: (try? engineToolkitClient.isXRD(resource: resourceAddress, on: networkID)) ?? false,
				guarantee: guarantee()
			))]

		case (let .ids(_, ids), .nonFungibleResource):
			// https://rdxworks.slack.com/archives/C02MTV9602H/p1681155601557349
			let maximumNFTIDChunkSize = 29

			var result: [Transfer] = []
			for idChunk in ids.chunks(ofCount: maximumNFTIDChunkSize) {
				let tokens = try await gatewayAPIClient.getNonFungibleData(.init(
					resourceAddress: resourceAddress.address,
					nonFungibleIds: idChunk.map { try $0.toString() }
				))
				.nonFungibleIds
				.map {
					Transfer.nonFungible(.init(
						resourceName: metadata?.name,
						resourceImage: metadata?.iconURL,
						tokenID: $0.nonFungibleId.userFacingNonFungibleLocalID,
						tokenName: nil
					))
				}

				result.append(contentsOf: tokens)
			}

			return result

		default:
			return []
		}
	}
}

// MARK: Useful types

extension TransactionReview {
	public struct ProofEntity: Sendable, Identifiable, Hashable {
		public let id: ResourceAddress
		public let metadata: EntityMetadata
	}

	public struct DappEntity: Sendable, Identifiable, Hashable {
		public let id: DappDefinitionAddress
		public let metadata: EntityMetadata?
	}

	public struct EntityMetadata: Sendable, Hashable {
		public let name: String?
		public let thumbnail: URL?
		public let description: String?

		public init(metadata: GatewayAPI.EntityMetadataCollection?) {
			self.name = metadata?.name
			self.thumbnail = metadata?.iconURL
			self.description = metadata?.description
		}
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

	public enum Transfer: Sendable, Identifiable, Hashable {
		public typealias ID = Tagged<Self, UUID>

		case fungible(FungibleTransfer)
		case nonFungible(NonFungibleTransfer)

		public var id: ID {
			switch self {
			case let .fungible(details):
				return details.id
			case let .nonFungible(details):
				return details.id
			}
		}

		public var fungible: FungibleTransfer? {
			get {
				guard case let .fungible(details) = self else { return nil }
				return details
			}
			set {
				guard case .fungible = self, let newValue else { return }
				self = .fungible(newValue)
			}
		}

		public var nonFungible: NonFungibleTransfer? {
			get {
				guard case let .nonFungible(details) = self else { return nil }
				return details
			}
			set {
				guard case .nonFungible = self, let newValue else { return }
				self = .nonFungible(newValue)
			}
		}
	}

	public struct FungibleTransfer: Sendable, Hashable {
		public let id = Transfer.ID()
		public let amount: BigDecimal
		public let name: String?
		public let symbol: String?
		public let thumbnail: URL?
		public let isXRD: Bool
		public var guarantee: TransactionClient.Guarantee?
	}

	public struct NonFungibleTransfer: Sendable, Hashable {
		public let id = Transfer.ID()
		public let resourceName: String?
		public let resourceImage: URL?
		public let tokenID: String
		public let tokenName: String?
	}
}

extension TransactionReview.State {
	public var allGuarantees: [TransactionClient.Guarantee] {
		deposits?.accounts.flatMap { $0.transfers.compactMap(\.fungible?.guarantee) } ?? []
	}

	public mutating func applyGuarantee(_ updated: TransactionClient.Guarantee, transferID: TransactionReview.Transfer.ID) {
		guard let accountID = accountID(for: transferID) else { return }
		deposits?.accounts[id: accountID]?.transfers[id: transferID]?.fungible?.guarantee = updated
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

// MARK: Helpers

extension [TransactionReview.Account] {
	struct MissingUserAccountError: Error {}

	func account(for componentAddress: ComponentAddress) throws -> TransactionReview.Account {
		guard let account = first(where: { $0.address.address == componentAddress.address }) else {
			loggerGlobal.error("Can't find component address that was specified for transfer")
			throw MissingUserAccountError()
		}

		return account
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

extension AccountDeposit {
	public var componentAddress: ComponentAddress {
		switch self {
		case let .exact(componentAddress, _), let .estimate(_, componentAddress, _):
			return componentAddress
		}
	}

	public var resourceSpecifier: ResourceSpecifier {
		switch self {
		case let .exact(_, resourceSpecifier), let .estimate(_, _, resourceSpecifier):
			return resourceSpecifier
		}
	}

	var transferType: TransactionReview.TransferType {
		switch self {
		case .exact:
			return .exact
		case let .estimate(index, _, _):
			return .estimated(instructionIndex: index)
		}
	}
}

extension ResourceSpecifier {
	var resourceAddress: ResourceAddress {
		switch self {
		case let .amount(resourceAddress, _), let .ids(resourceAddress, _):
			return resourceAddress
		}
	}
}

// TODO: Remove once RET is migrated to `ash`, this is meant to be temporary
extension NonFungibleLocalIdInternal {
	struct InvalidLocalID: Error {}

	public func toString() throws -> String {
		switch self {
		case let .integer(value):
			return "#\(value)#"
		case .uuid:
			throw InvalidLocalID()
		case let .string(value):
			return "<\(value)>"
		case let .bytes(value):
			guard let string = String(data: value.data, encoding: .utf8) else {
				throw InvalidLocalID()
			}
			return "[\(string)]"
		}
	}
}

// MARK: - SimpleDappDetails
// FIXME: Remove and make settings use stacks

public struct SimpleDappDetails: Sendable, FeatureReducer {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.cacheClient) var cacheClient

	public struct FailedToLoadMetadata: Error, Hashable {}

	public typealias Store = StoreOf<Self>

	// MARK: State

	public struct State: Sendable, Hashable {
		public var dAppID: DappDefinitionAddress

		@Loadable
		public var metadata: GatewayAPI.EntityMetadataCollection? = nil

		@Loadable
		public var resources: Resources? = nil

		@Loadable
		public var associatedDapps: [AssociatedDapp]? = nil

		public init(
			dAppID: DappDefinitionAddress,
			metadata: GatewayAPI.EntityMetadataCollection? = nil,
			resources: Resources? = nil,
			associatedDapps: [AssociatedDapp]? = nil
		) {
			self.dAppID = dAppID
			self.metadata = metadata
			self.resources = resources
			self.associatedDapps = associatedDapps
		}

		public struct Resources: Hashable, Sendable {
			public var fungible: [ResourceDetails]
			public var nonFungible: [ResourceDetails]

			// TODO: This should be consolidated with other types that represent resources
			public struct ResourceDetails: Identifiable, Hashable, Sendable {
				public var id: ResourceAddress { address }

				public let address: ResourceAddress
				public let fungibility: Fungibility
				public let name: String
				public let symbol: String?
				public let description: String?
				public let iconURL: URL?

				public enum Fungibility: Hashable, Sendable {
					case fungible
					case nonFungible
				}
			}
		}

		// TODO: This should be consolidated with other types that represent resources
		public struct AssociatedDapp: Identifiable, Hashable, Sendable {
			public var id: DappDefinitionAddress { address }

			public let address: DappDefinitionAddress
			public let name: String
			public let iconURL: URL?
		}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case openURLTapped(URL)
	}

	public enum InternalAction: Sendable, Equatable {
		case metadataLoaded(Loadable<GatewayAPI.EntityMetadataCollection>)
		case resourcesLoaded(Loadable<State.Resources>)
		case associatedDappsLoaded(Loadable<[State.AssociatedDapp]>)
	}

	// MARK: - Destination

	// MARK: Reducer

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			state.$metadata = .loading
			state.$resources = .loading
			return .task { [dAppID = state.dAppID] in
				let result = await TaskResult {
					try await cacheClient.withCaching(
						cacheEntry: .dAppMetadata(dAppID.address),
						request: {
							try await gatewayAPIClient.getEntityMetadata(dAppID.address)
						}
					)
				}
				return .internal(.metadataLoaded(.init(result: result)))
			}

		case let .openURLTapped(url):
			return .fireAndForget {
				await openURL(url)
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .metadataLoaded(metadata):
			state.$metadata = metadata

			let dAppDefinitionAddress = state.dAppID
			return .run { send in
				let resources = await metadata.flatMap { await loadResources(metadata: $0, validated: dAppDefinitionAddress) }
				await send(.internal(.resourcesLoaded(resources)))

				let associatedDapps = await metadata.flatMap { await loadDapps(metadata: $0, validated: dAppDefinitionAddress) }
				await send(.internal(.associatedDappsLoaded(associatedDapps)))
			}

		case let .resourcesLoaded(resources):
			state.$resources = resources
			return .none

		case let .associatedDappsLoaded(dApps):
			state.$associatedDapps = dApps
			return .none
		}
	}

	/// Loads any fungible and non-fungible resources associated with the dApp
	private func loadResources(
		metadata: GatewayAPI.EntityMetadataCollection,
		validated dappDefinitionAddress: DappDefinitionAddress
	) async -> Loadable<SimpleDappDetails.State.Resources> {
		guard let claimedEntities = metadata.claimedEntities, !claimedEntities.isEmpty else {
			return .idle
		}

		let result = await TaskResult {
			let allResourceItems = try await gatewayAPIClient.fetchResourceDetails(claimedEntities)
				.items
				// FIXME: Uncomment this when when we can rely on dApps conforming to the standards
				// .filter { $0.metadata.dappDefinition == dAppDefinitionAddress.address }
				.compactMap(\.resourceDetails)

			return State.Resources(fungible: allResourceItems.filter { $0.fungibility == .fungible },
			                       nonFungible: allResourceItems.filter { $0.fungibility == .nonFungible })
		}

		return .init(result: result)
	}

	/// Loads any other dApps associated with the dApp
	private func loadDapps(
		metadata: GatewayAPI.EntityMetadataCollection,
		validated dappDefinitionAddress: DappDefinitionAddress
	) async -> Loadable<[State.AssociatedDapp]> {
		let dAppDefinitions = try? metadata.dappDefinitions?.compactMap(DappDefinitionAddress.init)
		guard let dAppDefinitions else { return .idle }

		let associatedDapps = await dAppDefinitions.parallelMap { dApp in
			try? await extractDappInfo(for: dApp, validating: dappDefinitionAddress)
		}
		.compactMap { $0 }

		guard !associatedDapps.isEmpty else { return .idle }

		return .success(associatedDapps)
	}

	/// Helper function that loads and extracts dApp info for a given dApp, validating that it points back to the dApp of this screen
	private func extractDappInfo(
		for dApp: DappDefinitionAddress,
		validating dAppDefinitionAddress: DappDefinitionAddress
	) async throws -> State.AssociatedDapp {
		let metadata = try await gatewayAPIClient.getEntityMetadata(dApp.address)
		// FIXME: Uncomment this when when we can rely on dApps conforming to the standards
		// .validating(dAppDefinitionAddress: dAppDefinitionAddress)
		guard let name = metadata.name else {
			throw GatewayAPI.EntityMetadataCollection.MetadataError.missingName
		}
		return .init(address: dApp, name: name, iconURL: metadata.iconURL)
	}
}

extension GatewayAPI.StateEntityDetailsResponseItem {
	var resourceDetails: SimpleDappDetails.State.Resources.ResourceDetails? {
		guard let fungibility else { return nil }
		return .init(address: .init(address: address),
		             fungibility: fungibility,
		             name: metadata.name ?? L10n.AuthorizedDapps.DAppDetails.unknownTokenName,
		             symbol: metadata.symbol,
		             description: metadata.description,
		             iconURL: metadata.iconURL)
	}

	private var fungibility: SimpleDappDetails.State.Resources.ResourceDetails.Fungibility? {
		guard let details else { return nil }
		switch details {
		case .fungibleResource:
			return .fungible
		case .nonFungibleResource:
			return .nonFungible
		case .fungibleVault, .nonFungibleVault, .package, .component:
			return nil
		}
	}
}
