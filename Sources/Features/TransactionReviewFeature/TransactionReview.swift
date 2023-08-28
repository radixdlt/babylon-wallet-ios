import AppPreferencesClient
import AssetsFeature
import ComposableArchitecture
import CryptoKit
import EngineKit
import FactorSourcesClient
import FeaturePrelude
import GatewayAPI
import OnLedgerEntitiesClient
import SigningFeature
import TransactionClient

// MARK: - TransactionReview
public struct TransactionReview: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var displayMode: DisplayMode = .review

		public let nonce: Nonce
		public let transactionManifest: TransactionManifest
		public let message: Message
		public let signTransactionPurpose: SigningPurpose.SignTransactionPurpose
		public var networkID: NetworkID? {
			reviewedTransaction?.networkId
		}

		public var reviewedTransaction: ReviewedTransaction? = nil

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
			message: Message,
			ephemeralNotaryPrivateKey: Curve25519.Signing.PrivateKey = .init()
		) {
			self.nonce = nonce
			self.transactionManifest = transactionManifest
			self.signTransactionPurpose = signTransactionPurpose
			self.message = message
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
		case defaultDepositGuaranteeLoaded(BigDecimal)
		case previewLoaded(TaskResult<TransactionToReview>)
		case createTransactionReview(TransactionReview.TransactionContent)
		case buildTransactionItentResult(TaskResult<TransactionIntent>)
		case loadedOnLedgerResource(Transfer, TaskResult<OnLedgerEntity.Resource>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case failed(TransactionFailure)
		case signedTXAndSubmittedToGateway(TXID)
		case transactionCompleted(TXID)
		case userDismissedTransactionStatus
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case customizeGuarantees(TransactionReviewGuarantees.State)
			case signing(Signing.State)
			case submitting(SubmitTransaction.State)
			case dApp(SimpleDappDetails.State)
			case customizeFees(CustomizeFees.State)
			case fungibleTokenDetails(FungibleTokenDetails.State)
			case nonFungibleTokenDetails(NonFungibleTokenDetails.State)
		}

		public enum Action: Sendable, Equatable {
			case customizeGuarantees(TransactionReviewGuarantees.Action)
			case signing(Signing.Action)
			case submitting(SubmitTransaction.Action)
			case dApp(SimpleDappDetails.Action)
			case customizeFees(CustomizeFees.Action)
			case fungibleTokenDetails(FungibleTokenDetails.Action)
			case nonFungibleTokenDetails(NonFungibleTokenDetails.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.customizeGuarantees, action: /Action.customizeGuarantees) {
				TransactionReviewGuarantees()
			}
			Scope(state: /State.customizeFees, action: /Action.customizeFees) {
				CustomizeFees()
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
			Scope(state: /State.fungibleTokenDetails, action: /Action.fungibleTokenDetails) {
				FungibleTokenDetails()
			}
			Scope(state: /State.nonFungibleTokenDetails, action: /Action.nonFungibleTokenDetails) {
				NonFungibleTokenDetails()
			}
		}
	}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.transactionClient) var transactionClient
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
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
			return .run { [nonce = state.nonce, message = state.message, notary = state.ephemeralNotaryPrivateKey.publicKey] send in
				let defaultDepositGuarantees = await appPreferencesClient.getPreferences().transaction.defaultDepositGuarantee
				await send(.internal(.defaultDepositGuaranteeLoaded(defaultDepositGuarantees)))

				let preview = await TaskResult {
					try await transactionClient.getTransactionReview(.init(
						manifestToSign: manifest,
						message: message,
						nonce: nonce,
						ephemeralNotaryPublicKey: notary
					))
				}
				await send(.internal(.previewLoaded(preview)))
			}

		case .closeTapped:
			return .none

		case .showRawTransactionTapped:
			switch state.displayMode {
			case .review:
				return showRawTransaction(&state)
			case .raw:
				state.displayMode = .review
				return .none
			}

		case .approveTapped:
			state.canApproveTX = false
			do {
				let manifest = try transactionManifestWithWalletInstructionsAdded(state)
				guard let reviewedTransaction = state.reviewedTransaction else {
					assertionFailure("Expected reviewedTransaction")
					return .none
				}

				guard let networkID = state.networkID else {
					assertionFailure("Expected networkID")
					return .none
				}

				let tipPercentage: UInt16 = {
					switch reviewedTransaction.feePayerSelection.transactionFee.mode {
					case .normal:
						return 0
					case let .advanced(customization):
						let converted = UInt16(truncatingIfNeeded: customization.tipPercentage.integerValue)
						return converted
					}
				}()

				let request = BuildTransactionIntentRequest(
					networkID: networkID,
					manifest: manifest,
					message: state.message,
					makeTransactionHeaderInput: MakeTransactionHeaderInput(tipPercentage: tipPercentage),
					transactionSigners: reviewedTransaction.transactionSigners
				)

				#if DEBUG
				printSigners(reviewedTransaction)
				#endif

				return .task {
					await .internal(.buildTransactionItentResult(TaskResult {
						try await transactionClient.buildTransactionIntent(request).intent
					}))
				}
			} catch {
				errorQueue.schedule(error)
				return .none
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .withdrawals(.delegate(.showAsset(assetTransfer))),
		     let .deposits(.delegate(.showAsset(assetTransfer))):
			let metadata = state.reviewedTransaction?.metadataForNewlyCreatedResource(assetTransfer.resource)
			switch assetTransfer {
			case let .fungible(transfer):
				state.destination = .fungibleTokenDetails(.init(transfer: transfer, metadata: metadata))
			case let .nonFungible(transfer):
				do {
					state.destination = try .nonFungibleTokenDetails(.init(transfer: transfer, metadata: metadata))
				} catch {
					errorQueue.schedule(error)
				}
			}

			if metadata != nil {
				// Only newly created resources have metadata, if so it's pointless to call onLedgerEntitiesClient
				return .none
			}

			return .run { send in
				let result = await TaskResult {
					try await onLedgerEntitiesClient.getResource(assetTransfer.resource)
				}

				await send(.internal(.loadedOnLedgerResource(assetTransfer, result)))
			}

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

		case .networkFee(.delegate(.showCustomizeFees)):
			guard let reviewedTransaction = state.reviewedTransaction else {
				return .none
			}
			state.destination = .customizeFees(.init(reviewedTransaction: reviewedTransaction, manifest: state.transactionManifest))
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

		case let .customizeFees(.delegate(.updated(reviewedTransaction))):
			state.reviewedTransaction = reviewedTransaction
			if let reviewedTransaction = state.reviewedTransaction {
				state.networkFee = .init(reviewedTransaction: reviewedTransaction)
			}
			return .none

		case .customizeFees:
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

		case .fungibleTokenDetails(.delegate(.dismiss)):
			guard case .fungibleTokenDetails = state.destination else { return .none }
			state.destination = nil
			return .none

		case .fungibleTokenDetails:
			return .none

		case .nonFungibleTokenDetails(.delegate(.dismiss)):
			guard case .nonFungibleTokenDetails = state.destination else { return .none }
			state.destination = nil
			return .none

		case .nonFungibleTokenDetails:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .defaultDepositGuaranteeLoaded(defaultGuarantee):
			// FIXME: Apply guarantee
			return .none

		case let .previewLoaded(.failure(error)):
			return .send(.delegate(.failed(TransactionFailure.failedToPrepareTXReview(.failedToGenerateTXReview(error)))))

		case let .previewLoaded(.success(preview)):
			do {
				state.reviewedTransaction = try .init(
					feePayerSelection: preview.feePayerSelectionAmongstCandidates,
					networkId: preview.networkID,
					transaction: preview.analyzedManifestToReview.transactionTypes.transactionKind(),
					transactionSigners: preview.transactionSigners,
					signingFactors: preview.signingFactors
				)
				return review(&state)
			} catch {
				errorQueue.schedule(error)
				return .none
			}

		case let .createTransactionReview(content):
			state.withdrawals = content.withdrawals
			state.dAppsUsed = content.dAppsUsed
			state.deposits = content.deposits
			state.proofs = content.proofs
			state.networkFee = content.networkFee
			return .none

		case let .loadedOnLedgerResource(assetTransfer, .success(resource)):
			let kind = resource.resourceAddress.decodedKind
			// Now we also have the resource and we can update the details view
			switch (assetTransfer, kind) {
			case let (.fungible(transfer), .globalFungibleResourceManager):
				guard case .fungibleTokenDetails = state.destination else { return .none }
				state.destination = .fungibleTokenDetails(.init(transfer: transfer, resource: resource))
			case let (.nonFungible(transfer), .globalNonFungibleResourceManager):
				guard case .nonFungibleTokenDetails = state.destination else { return .none }
				do {
					state.destination = try .nonFungibleTokenDetails(.init(transfer: transfer, resource: resource))
				} catch {
					errorQueue.schedule(error)
				}
			default:
				struct OnLedgerError: Error {}
				errorQueue.schedule(OnLedgerError())
			}

			return .none

		case let .loadedOnLedgerResource(_, .failure(error)):
			loggerGlobal.warning("Failed to load on-ledger resource: \(error)")
			return .none

		case let .buildTransactionItentResult(.success(response)):
			guard let reviewedTransaction = state.reviewedTransaction else {
				return .none
			}
			state.destination = .signing(.init(
				factorsLeftToSignWith: reviewedTransaction.signingFactors,
				signingPurposeWithPayload: .signTransaction(
					ephemeralNotaryPrivateKey: state.ephemeralNotaryPrivateKey,
					response,
					origin: state.signTransactionPurpose
				)
			))
			return .none
		case let .buildTransactionItentResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}
}

extension TransactionReview {
	func review(_ state: inout State) -> EffectTask<Action> {
		guard let transactionToReview = state.reviewedTransaction else {
			assertionFailure("Bad implementation, expected `analyzedManifestToReview`")
			return .none
		}
		guard let networkID = state.networkID else {
			assertionFailure("Bad implementation, expected `networkID`")
			return .none
		}

		switch transactionToReview.transaction {
		case let .conforming(transaction):
			return .run { send in
				let userAccounts = try await extractUserAccounts(transaction)

				let content = await TransactionReview.TransactionContent(
					withdrawals: try? extractWithdrawals(
						transaction,
						userAccounts: userAccounts,
						networkID: networkID
					),
					dAppsUsed: try? extractUsedDapps(transaction),
					deposits: try? extractDeposits(
						transaction,
						userAccounts: userAccounts,
						networkID: networkID
					),
					proofs: try? exctractProofs(transaction),
					networkFee: .init(reviewedTransaction: transactionToReview)
				)
				await send(.internal(.createTransactionReview(content)))
			} catch: { error, _ in
				loggerGlobal.error("Failed to extract user accounts, error: \(error)")
				// FIXME: propagate/display error?
			}
		case .nonConforming:
			return showRawTransaction(&state)
		}
	}

	public func addingGuarantees(
		to manifest: TransactionManifest,
		guarantees: [TransactionClient.Guarantee]
	) throws -> TransactionManifest {
		guard !guarantees.isEmpty else { return manifest }

		var manifest = manifest

		/// Will be increased with each added guarantee to account for the difference in indexes from the initial manifest.
		var indexInc = 1 // LockFee was added, start from 1
		for guarantee in guarantees {
			let guaranteeInstruction: Instruction = try .assertWorktopContains(
				resourceAddress: guarantee.resourceAddress.intoEngine(),
				amount: .init(value: guarantee.amount.toString())
			)

			manifest = try manifest.withInstructionAdded(guaranteeInstruction, at: Int(guarantee.instructionIndex) + indexInc)

			indexInc += 1
		}
		return manifest
	}

	func showRawTransaction(_ state: inout State) -> EffectTask<Action> {
		do {
			let manifest = try transactionManifestWithWalletInstructionsAdded(state)
			let rawTransaction = try manifest.instructions().asStr()
			state.displayMode = .raw(rawTransaction)
		} catch {
			errorQueue.schedule(error)
		}
		return .none
	}

	func transactionManifestWithWalletInstructionsAdded(_ state: State) throws -> TransactionManifest {
		var manifest = state.transactionManifest
		if let feePayerSelection = state.reviewedTransaction?.feePayerSelection, let feePayer = feePayerSelection.selected {
			manifest = try manifest.withLockFeeCallMethodAdded(address: feePayer.account.address.asGeneral(), fee: feePayerSelection.transactionFee.totalFee.lockFee)
		}
		return try addingGuarantees(to: manifest, guarantees: state.allGuarantees)
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

	func cancelSigningEffect(state: inout State) -> EffectTask<Action> {
		loggerGlobal.notice("Cancelled signing")
		state.canApproveTX = true
		return .none
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
		case estimated(instructionIndex: UInt64)
	}

	private func extractUserAccounts(_ transaction: TransactionType.GeneralTransaction) async throws -> [Account] {
		let userAccounts = try await accountsClient.getAccountsOnCurrentNetwork()

		return transaction.allAddress
			.compactMap {
				try? AccountAddress(validatingAddress: $0.addressString())
			}
			.map { address in
				let userAccount = userAccounts.first { userAccount in
					userAccount.address == address
				}
				if let userAccount {
					return .user(.init(address: userAccount.address, label: userAccount.displayName, appearanceID: userAccount.appearanceID))
				} else {
					return .external(address, approved: false)
				}
			}
	}

	private func extractUsedDapps(_ transaction: TransactionType.GeneralTransaction) async throws -> TransactionReviewDappsUsed.State? {
		let dApps = try await transaction.allAddress
			.filter {
				$0.entityType() == .globalGenericComponent
			}
			.map { try $0.asSpecific() }
			.asyncMap(extractDappInfo)

		guard !dApps.isEmpty else { return nil }
		return TransactionReviewDappsUsed.State(isExpanded: true, dApps: .init(uniqueElements: Set(dApps)))
	}

	private func extractDappInfo(_ component: ComponentAddress) async throws -> DappEntity {
		let dAppDefinitionAddress = try await gatewayAPIClient.getDappDefinitionAddress(component)
		let metadata = try? await gatewayAPIClient.getDappMetadata(dAppDefinitionAddress)
			.validating(dAppComponent: component)

		return DappEntity(id: dAppDefinitionAddress, metadata: .init(metadata: metadata))
	}

	private func exctractProofs(_ transaction: TransactionType.GeneralTransaction) async throws -> TransactionReviewProofs.State? {
		let proofs = try await transaction.accountProofs
			.map { try ResourceAddress(validatingAddress: $0.addressString()) }
			.asyncMap(extractProofInfo)
		guard !proofs.isEmpty else { return nil }

		return TransactionReviewProofs.State(proofs: .init(uniqueElements: proofs))
	}

	private func extractProofInfo(_ address: ResourceAddress) async -> ProofEntity {
		await ProofEntity(
			id: address,
			metadata: .init(metadata: try? gatewayAPIClient.getEntityMetadata(address.address, .dappMetadataKeys))
		)
	}

	private func extractWithdrawals(
		_ transaction: TransactionType.GeneralTransaction,
		userAccounts: [Account],
		networkID: NetworkID
	) async throws -> TransactionReviewAccounts.State? {
		var withdrawals: [Account: [Transfer]] = [:]
		for (accountAddress, resources) in transaction.accountWithdraws {
			let account = try userAccounts.account(for: .init(validatingAddress: accountAddress))

			let transfers = try await resources.asyncFlatMap {
				try await transferInfo(
					resourceQuantifier: $0,
					metadataOfCreatedEntities: transaction.metadataOfNewlyCreatedEntities,
					createdEntities: transaction.addressesOfNewlyCreatedEntities,
					networkID: networkID,
					type: .exact
				)
			}

			withdrawals[account, default: []].append(contentsOf: transfers)
		}

		guard !withdrawals.isEmpty else { return nil }

		let accounts = withdrawals.map {
			TransactionReviewAccount.State(account: $0.key, transfers: .init(uniqueElements: $0.value))
		}
		return .init(accounts: .init(uniqueElements: accounts), showCustomizeGuarantees: false)
	}

	private func extractDeposits(
		_ transaction: TransactionType.GeneralTransaction,
		userAccounts: [Account],
		networkID: NetworkID
	) async throws -> TransactionReviewAccounts.State? {
		var deposits: [Account: [Transfer]] = [:]

		for (accountAddress, accountDeposits) in transaction.accountDeposits {
			let account = try userAccounts.account(for: .init(validatingAddress: accountAddress))

			let transfers = try await accountDeposits.asyncFlatMap {
				try await transferInfo(
					resourceQuantifier: $0,
					metadataOfCreatedEntities: transaction.metadataOfNewlyCreatedEntities,
					createdEntities: transaction.addressesOfNewlyCreatedEntities,
					networkID: networkID,
					type: $0.transferType
				)
			}

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
		resourceQuantifier: ResourceTracker,
		metadataOfCreatedEntities: [String: [String: MetadataValue?]]?,
		createdEntities: [EngineToolkit.Address],
		networkID: NetworkID,
		type: TransferType
	) async throws -> [Transfer] {
		let resourceAddress: ResourceAddress = try resourceQuantifier.resourceAddress.asSpecific()
		let isNewResource = createdEntities.contains(resourceQuantifier.resourceAddress)

		let metadata: (name: String?, symbol: String?, thumbnail: URL?) = await {
			if let newResourceMetadata = metadataOfCreatedEntities?[resourceAddress.address] {
				return (
					newResourceMetadata.name,
					newResourceMetadata.symbol,
					newResourceMetadata.iconURL
				)
			} else {
				let remoteMetadata = try? await gatewayAPIClient.getEntityMetadata(resourceAddress.address, [.name, .symbol, .iconURL])

				return (
					remoteMetadata?.name,
					remoteMetadata?.symbol,
					remoteMetadata?.iconURL
				)
			}
		}()

		switch resourceQuantifier {
		case let .fungible(_, source):
			let amount = try BigDecimal(fromString: source.amount.asStr())

			func guarantee() -> TransactionClient.Guarantee? {
				guard case let .predicted(instructionIndex, _) = source, !isNewResource else { return nil }
				return .init(amount: amount, instructionIndex: instructionIndex, resourceAddress: resourceAddress)
			}

			return [.fungible(.init(
				resource: resourceAddress,
				amount: amount,
				name: metadata.name,
				symbol: metadata.symbol,
				thumbnail: metadata.thumbnail,
				isXRD: resourceAddress.isXRD(on: networkID),
				guarantee: guarantee()
			))]
		case let .nonFungible(_, _, .guaranteed(ids)),
		     let .nonFungible(_, _, ids: .predicted(instructionIndex: _, value: ids)):
			if isNewResource {
				return try ids.map { id in
					try Transfer.nonFungible(.init(
						resource: resourceAddress,
						resourceName: metadata.name,
						resourceImage: metadata.thumbnail,
						tokenID: id.toString().userFacingNonFungibleLocalID,
						tokenName: nil
					))
				}
			}

			let maximumNFTIDChunkSize = 29

			var result: [Transfer] = []
			for idChunk in ids.chunks(ofCount: maximumNFTIDChunkSize) {
				let tokens = try await gatewayAPIClient.getNonFungibleData(.init(
					resourceAddress: resourceAddress.address,
					nonFungibleIds: idChunk.map {
						try $0.toString()
					}
				))
				.nonFungibleIds
				.map {
					Transfer.nonFungible(.init(
						resource: resourceAddress,
						resourceName: metadata.name,
						resourceImage: metadata.thumbnail,
						tokenID: $0.nonFungibleId.userFacingNonFungibleLocalID,
						tokenName: nil
					))
				}

				result.append(contentsOf: tokens)
			}

			return result
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

		public var resource: ResourceAddress {
			switch self {
			case let .fungible(details):
				return details.resource
			case let .nonFungible(details):
				return details.resource
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
		public let resource: ResourceAddress
		public let amount: BigDecimal
		public let name: String?
		public let symbol: String?
		public let thumbnail: URL?
		public let isXRD: Bool
		public var guarantee: TransactionClient.Guarantee?
	}

	public struct NonFungibleTransfer: Sendable, Hashable {
		public let id = Transfer.ID()
		public let resource: ResourceAddress
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

extension ResourceTracker {
	var transferType: TransactionReview.TransferType {
		switch decimalSource {
		case .guaranteed:
			return .exact
		case let .predicted(instructionIndex, _):
			return .estimated(instructionIndex: instructionIndex)
		}
	}
}

extension NonFungibleLocalIdVecSource {
	var ids: [NonFungibleLocalId] {
		switch self {
		case let .guaranteed(value):
			return value
		case let .predicted(_, value):
			return value
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
							try await gatewayAPIClient.getEntityMetadata(dAppID.address, .dappMetadataKeys)
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
			let allResourceItems = try await gatewayAPIClient.fetchResourceDetails(claimedEntities, explicitMetadata: .resourceMetadataKeys)
				.items
				// FIXME: Uncomment this when when we can rely on dApps conforming to the standards
				// .filter { $0.metadata.dappDefinition == dAppDefinitionAddress.address }
				.compactMap {
					try $0.resourceDetails()
				}

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
		let metadata = try await gatewayAPIClient.getEntityMetadata(dApp.address, [.name, .iconURL])
		// FIXME: Uncomment this when when we can rely on dApps conforming to the standards
		// .validating(dAppDefinitionAddress: dAppDefinitionAddress)
		guard let name = metadata.name else {
			throw GatewayAPI.EntityMetadataCollection.MetadataError.missingName
		}
		return .init(address: dApp, name: name, iconURL: metadata.iconURL)
	}
}

extension GatewayAPI.StateEntityDetailsResponseItem {
	func resourceDetails() throws -> SimpleDappDetails.State.Resources.ResourceDetails? {
		guard let fungibility else { return nil }
		let address = try ResourceAddress(validatingAddress: address)
		return .init(address: address,
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

// MARK: - ReviewedTransaction
public struct ReviewedTransaction: Hashable, Sendable {
	var feePayerSelection: FeePayerSelectionAmongstCandidates
	let networkId: NetworkID
	let transaction: TransactionKind

	var transactionSigners: TransactionSigners
	var signingFactors: SigningFactors
}

// MARK: - FeeValidationOutcome
enum FeeValidationOutcome {
	case valid
	case needsFeePayer
	case insufficientBalance
}

extension ReviewedTransaction {
	var feePayingValidation: FeeValidationOutcome {
		switch transaction {
		case .nonConforming:
			return feePayerSelection.validate
		case let .conforming(generalTransaction):
			guard let feePayer = feePayerSelection.selected,
			      let feePayerWithdraws = generalTransaction.accountWithdraws[feePayer.account.address.address]
			else {
				return feePayerSelection.validate
			}

			let xrdAddress = knownAddresses(networkId: networkId.rawValue).resourceAddresses.xrd

			let totalXRDWithdraw = feePayerWithdraws.reduce(EngineKit.Decimal.zero()) { partialResult, resource in
				if case let .fungible(resourceAddress, source) = resource, resourceAddress == xrdAddress {
					return (try? partialResult.add(other: source.amount)) ?? partialResult
				}
				return partialResult
			}

			// Convert from EngineKit decimal
			let xrdTotalTransfer = (try? BigDecimal(fromString: totalXRDWithdraw.asStr())) ?? .zero

			let total = xrdTotalTransfer + feePayerSelection.transactionFee.totalFee.lockFee

			guard feePayer.xrdBalance >= total else {
				// Insufficient balance to pay for withdraws and transaction fee
				return .insufficientBalance
			}

			return .valid
		}
	}
}

extension FeePayerSelectionAmongstCandidates {
	var validate: FeeValidationOutcome {
		if transactionFee.totalFee.lockFee == .zero {
			// If no fee is required - valid
			return .valid
		}

		guard let selected else {
			// If fee is required, but no fee payer selected - invalid
			return .needsFeePayer
		}

		guard selected.xrdBalance >= transactionFee.totalFee.lockFee else {
			// If insufficient balance - invalid
			return .insufficientBalance
		}

		return .valid
	}
}

func printSigners(_ reviewedTransaction: ReviewedTransaction) {
	for (factorSourceKind, signingFactorsOfKind) in reviewedTransaction.signingFactors {
		print("🔮 ~~~ SIGNINGFACTORS OF KIND: \(factorSourceKind) #\(signingFactorsOfKind.count) many: ~~~")
		for signingFactor in signingFactorsOfKind {
			let factorSource = signingFactor.factorSource
			print("\t🔮 == Signers for factorSource: \(factorSource.id): ==")
			for signer in signingFactor.signers {
				let entity = signer.entity
				print("\t\t🔮 * Entity: \(entity.displayName): *")
				for factorInstance in signer.factorInstancesRequiredToSign {
					print("\t\t\t🔮 * FactorInstance: \(String(describing: factorInstance.derivationPath)) \(factorInstance.publicKey)")
				}
			}
		}
	}
}

extension ReviewedTransaction {
	func metadataForNewlyCreatedResource(_ resource: ResourceAddress) -> [String: MetadataValue?]? {
		guard case let .conforming(conforming) = transaction else { return nil }
		return conforming.metadataOfNewlyCreatedEntities[resource.address]
	}
}
