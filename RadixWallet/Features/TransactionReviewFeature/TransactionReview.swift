import ComposableArchitecture
import SwiftUI

// MARK: - TransactionReview
struct TransactionReview: Sendable, FeatureReducer {
	typealias Common = InteractionReviewCommon

	struct State: Sendable, Hashable {
		var displayMode: Common.DisplayMode = .detailed

		let nonce: Nonce
		let unvalidatedManifest: UnvalidatedTransactionManifest
		let message: Message
		let signTransactionPurpose: SigningPurpose.SignTransactionPurpose
		let waitsForTransactionToBeComitted: Bool
		let isWalletTransaction: Bool
		let proposingDappMetadata: DappMetadata.Ledger?
		let p2pRoute: P2P.Route

		var networkID: NetworkID? { reviewedTransaction?.networkID }

		var reviewedTransaction: ReviewedTransaction? = nil

		var withdrawals: Common.Accounts.State? = nil
		var dAppsUsed: TransactionReviewDappsUsed.State? = nil
		var contributingToPools: TransactionReviewPools.State? = nil
		var redeemingFromPools: TransactionReviewPools.State? = nil
		var deposits: Common.Accounts.State? = nil

		var stakingToValidators: ValidatorsState? = nil
		var unstakingFromValidators: ValidatorsState? = nil
		var claimingFromValidators: ValidatorsState? = nil

		var accountDepositSetting: DepositSettingState? = nil
		var accountDepositExceptions: DepositExceptionsState? = nil

		var proofs: Common.Proofs.State? = nil
		var networkFee: TransactionReviewNetworkFee.State? = nil
		let ephemeralNotaryPrivateKey: Curve25519.Signing.PrivateKey
		var canApproveTX: Bool = true
		var sliderResetDate: Date = .now

		@PresentationState
		var destination: Destination.State? = nil

		func printFeePayerInfo(line: UInt = #line, function: StaticString = #function) {
			#if DEBUG
			func doPrint(_ msg: String) {
				loggerGlobal.info("\(function)#\(line) - \(msg)")
			}
			let intentSignersNonEmpty = reviewedTransaction?.transactionSigners.intentSignerEntitiesNonEmptyOrNil()
			let feePayer = reviewedTransaction?.feePayer.unwrap()?.account.wrappedValue

			let notaryIsSignatory: Bool = reviewedTransaction?.transactionSigners.notaryIsSignatory == true
			switch (intentSignersNonEmpty, feePayer) {
			case (.none, .none):
				doPrint("NO Feepayer or intentSigner - faucet TX⁈ (notaryIsSignatory: \(notaryIsSignatory)")
				if !notaryIsSignatory {
					assertionFailure("Should not happen")
				}
			case let (.some(_intentSigners), .some(feePayer)):
				doPrint("Fee payer: \(feePayer.address), intentSigners: \(_intentSigners.map(\.address))")
			case let (.some(_intentSigners), .none):
				doPrint("No Fee payer, no account with enough money?, got intentSigners: \(_intentSigners.map(\.address)) ")
			case let (.none, .some(feePayer)):
				doPrint("‼️Fee payer: \(feePayer.address), but no intentSigners")
				assertionFailure("Should not happen")
			}
			#endif
		}

		mutating func resetSlider() {
			sliderResetDate = .now
		}

		init(
			unvalidatedManifest: UnvalidatedTransactionManifest,
			nonce: Nonce,
			signTransactionPurpose: SigningPurpose.SignTransactionPurpose,
			message: Message,
			ephemeralNotaryPrivateKey: Curve25519.Signing.PrivateKey = .init(),
			waitsForTransactionToBeComitted: Bool = false,
			isWalletTransaction: Bool,
			proposingDappMetadata: DappMetadata.Ledger?,
			p2pRoute: P2P.Route
		) {
			self.nonce = nonce
			self.unvalidatedManifest = unvalidatedManifest
			self.signTransactionPurpose = signTransactionPurpose
			self.message = message
			self.ephemeralNotaryPrivateKey = ephemeralNotaryPrivateKey
			self.waitsForTransactionToBeComitted = waitsForTransactionToBeComitted
			self.isWalletTransaction = isWalletTransaction
			self.proposingDappMetadata = proposingDappMetadata
			self.p2pRoute = p2pRoute
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case showRawTransactionTapped
		case copyRawTransactionTapped
		case expandContributingToPoolsTapped
		case expandRedeemingFromPoolsTapped
		case expandStakingToValidatorsTapped
		case expandUnstakingFromValidatorsTapped
		case expandClaimingFromValidatorsTapped
		case expandUsingDappsTapped
		case approvalSliderSlid
	}

	enum ChildAction: Sendable, Equatable {
		case withdrawals(Common.Accounts.Action)
		case deposits(Common.Accounts.Action)
		case dAppsUsed(TransactionReviewDappsUsed.Action)
		case contributingToPools(TransactionReviewPools.Action)
		case redeemingFromPools(TransactionReviewPools.Action)
		case proofs(Common.Proofs.Action)
		case networkFee(TransactionReviewNetworkFee.Action)
	}

	enum InternalAction: Sendable, Equatable {
		case previewLoaded(TaskResult<TransactionToReview>)
		case updateSections(Common.Sections?)
		case buildTransactionIntentResult(TaskResult<TransactionIntent>)
		case notarizeResult(TaskResult<NotarizeTransactionResponse>)
		case determineFeePayerResult(TaskResult<FeePayerSelectionResult?>)
	}

	enum DelegateAction: Sendable, Equatable {
		case failed(TransactionFailure)
		case signedTXAndSubmittedToGateway(IntentHash)
		case transactionCompleted(IntentHash)
		case dismiss
	}

	struct Destination: DestinationReducer {
		enum State: Sendable, Hashable {
			case customizeGuarantees(TransactionReviewGuarantees.State)
			case signing(Signing.State)
			case submitting(SubmitTransaction.State)
			case dApp(DappDetails.State)
			case customizeFees(CustomizeFees.State)
			case fungibleTokenDetails(FungibleTokenDetails.State)
			case nonFungibleTokenDetails(NonFungibleTokenDetails.State)
			case poolUnitDetails(PoolUnitDetails.State)
			case lsuDetails(LSUDetails.State)
			case unknownDappComponents(UnknownDappComponents.State)
			case rawTransactionAlert(AlertState<Action.RawTransactionAlert>)
		}

		enum Action: Sendable, Equatable {
			case customizeGuarantees(TransactionReviewGuarantees.Action)
			case signing(Signing.Action)
			case submitting(SubmitTransaction.Action)
			case dApp(DappDetails.Action)
			case customizeFees(CustomizeFees.Action)
			case fungibleTokenDetails(FungibleTokenDetails.Action)
			case nonFungibleTokenDetails(NonFungibleTokenDetails.Action)
			case lsuDetails(LSUDetails.Action)
			case poolUnitDetails(PoolUnitDetails.Action)
			case unknownDappComponents(UnknownDappComponents.Action)
			case rawTransactionAlert(RawTransactionAlert)

			enum RawTransactionAlert: Sendable, Equatable {
				case continueTapped
			}
		}

		var body: some ReducerOf<Self> {
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
				DappDetails()
			}
			Scope(state: /State.fungibleTokenDetails, action: /Action.fungibleTokenDetails) {
				FungibleTokenDetails()
			}
			Scope(state: /State.nonFungibleTokenDetails, action: /Action.nonFungibleTokenDetails) {
				NonFungibleTokenDetails()
			}
			Scope(state: /State.poolUnitDetails, action: /Action.poolUnitDetails) {
				PoolUnitDetails()
			}
			Scope(state: /State.lsuDetails, action: /Action.lsuDetails) {
				LSUDetails()
			}
			Scope(state: /State.unknownDappComponents, action: /Action.unknownDappComponents) {
				UnknownDappComponents()
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
	@Dependency(\.pasteboardClient) var pasteboardClient

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.networkFee, action: /Action.child .. ChildAction.networkFee) {
				TransactionReviewNetworkFee()
			}
			.ifLet(\.deposits, action: /Action.child .. ChildAction.deposits) {
				Common.Accounts()
			}
			.ifLet(\.dAppsUsed, action: /Action.child .. ChildAction.dAppsUsed) {
				TransactionReviewDappsUsed()
			}
			.ifLet(\.contributingToPools, action: /Action.child .. ChildAction.contributingToPools) {
				TransactionReviewPools()
			}
			.ifLet(\.redeemingFromPools, action: /Action.child .. ChildAction.redeemingFromPools) {
				TransactionReviewPools()
			}
			.ifLet(\.withdrawals, action: /Action.child .. ChildAction.withdrawals) {
				Common.Accounts()
			}
			.ifLet(\.proofs, action: /Action.child .. ChildAction.proofs) {
				Common.Proofs()
			}
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .run { [state = state] send in
				let preview = await TaskResult {
					try await transactionClient.getTransactionReview(.init(
						unvalidatedManifest: state.unvalidatedManifest,
						message: state.message,
						nonce: state.nonce,
						ephemeralNotaryPublicKey: state.ephemeralNotaryPrivateKey.publicKey,
						signingPurpose: .signTransaction(state.signTransactionPurpose),
						isWalletTransaction: state.isWalletTransaction
					))
				}
				await send(.internal(.previewLoaded(preview)))
			}

		case .showRawTransactionTapped:
			switch state.displayMode {
			case .detailed:
				return showRawTransaction(&state)
			case .raw:
				state.displayMode = .detailed
				return .none
			}

		case .copyRawTransactionTapped:
			guard case let .raw(manifest) = state.displayMode else {
				assertionFailure("Copy raw manifest button should only be visible in raw transaction mode")
				return .none
			}
			pasteboardClient.copyString(manifest)
			return .none

		case .expandContributingToPoolsTapped:
			state.contributingToPools?.isExpanded.toggle()
			return .none

		case .expandRedeemingFromPoolsTapped:
			state.redeemingFromPools?.isExpanded.toggle()
			return .none

		case .expandStakingToValidatorsTapped:
			state.stakingToValidators?.isExpanded.toggle()
			return .none

		case .expandUnstakingFromValidatorsTapped:
			state.unstakingFromValidators?.isExpanded.toggle()
			return .none

		case .expandClaimingFromValidatorsTapped:
			state.claimingFromValidators?.isExpanded.toggle()
			return .none

		case .expandUsingDappsTapped:
			state.dAppsUsed?.isExpanded.toggle()
			return .none

		case .approvalSliderSlid:
			state.canApproveTX = false
			state.printFeePayerInfo()
			do {
				let manifest = try transactionManifestWithWalletInstructionsAdded(state)
				guard let reviewedTransaction = state.reviewedTransaction else {
					assertionFailure("Expected reviewedTransaction")
					return .none
				}

				let tipPercentage: UInt16 = switch reviewedTransaction.transactionFee.mode {
				case .normal:
					0
				case let .advanced(customization):
					customization.tipPercentage
				}

				let request = BuildTransactionIntentRequest(
					networkID: reviewedTransaction.networkID,
					manifest: manifest,
					message: state.message,
					makeTransactionHeaderInput: MakeTransactionHeaderInput(tipPercentage: tipPercentage),
					transactionSigners: reviewedTransaction.transactionSigners
				)

				#if DEBUG
				printSigners(reviewedTransaction)
				#endif

				return .run { send in
					await send(.internal(.buildTransactionIntentResult(TaskResult {
						try await transactionClient.buildTransactionIntent(request)
					})))
				}
			} catch {
				loggerGlobal.critical("Failed to add instruction to add instructions to manifest, error: \(error)")
				errorQueue.schedule(error)
				return resetToApprovable(&state)
			}
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .withdrawals(.delegate(.showAsset(transfer, token))),
		     let .deposits(.delegate(.showAsset(transfer, token))):
			return resourceDetailsEffect(state: &state, resource: transfer.resource, details: transfer.details, nft: token)

		case let .dAppsUsed(.delegate(.openDapp(dAppID))), let .contributingToPools(.delegate(.openDapp(dAppID))), let .redeemingFromPools(.delegate(.openDapp(dAppID))):
			state.destination = .dApp(.init(dAppDefinitionAddress: dAppID))
			return .none

		case let .dAppsUsed(.delegate(.openUnknownAddresses(components))):
			state.destination = .unknownDappComponents(.init(
				title: L10n.TransactionReview.unknownComponents(components.count),
				rowHeading: L10n.Common.component,
				addresses: components.map { .component($0) }
			))
			return .none

		case let .contributingToPools(.delegate(.openUnknownAddresses(pools))), let .redeemingFromPools(.delegate(.openUnknownAddresses(pools))):
			state.destination = .unknownDappComponents(.init(
				title: L10n.TransactionReview.unknownPools(pools.count),
				rowHeading: L10n.Common.pool,
				addresses: pools.map { .resourcePool($0) }
			))
			return .none

		case .deposits(.delegate(.showCustomizeGuarantees)):
			guard let guarantees = state.deposits?.accounts.customizableGuarantees, !guarantees.isEmpty else { return .none }
			state.destination = .customizeGuarantees(.init(guarantees: guarantees.asIdentified()))

			return .none

		case let .proofs(.delegate(.showAsset(proof))):
			let resource = proof.resourceBalance.resource
			return resourceDetailsEffect(state: &state, resource: resource, details: proof.resourceBalance.details)

		case .networkFee(.delegate(.showCustomizeFees)):
			guard let reviewedTransaction = state.reviewedTransaction else {
				return .none
			}
			state.destination = .customizeFees(.init(
				reviewedTransaction: reviewedTransaction,
				manifestSummary: reviewedTransaction
					.transactionManifest
					.summary,
				signingPurpose: .signTransaction(state.signTransactionPurpose)
			))
			return .none

		default:
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .previewLoaded(.failure(error)):
			loggerGlobal.error("Transaction preview failed, error: \(error)")
			errorQueue.schedule(TransactionReviewFailure(underylying: error))
			return .send(.delegate(.failed(TransactionFailure.failedToPrepareTXReview(.failedToGenerateTXReview(error)))))

		case let .previewLoaded(.success(preview)):
			let reviewedTransaction = ReviewedTransaction(
				transactionManifest: preview.transactionManifest,
				networkID: preview.networkID,
				feePayer: .loading,
				transactionFee: preview.transactionFee,
				transactionSigners: preview.transactionSigners,
				signingFactors: preview.signingFactors,
				accountWithdraws: preview.analyzedManifestToReview.withdrawals,
				accountDeposits: preview.analyzedManifestToReview.deposits,
				isNonConforming: preview.analyzedManifestToReview.detailedManifestClass == nil
			)

			state.reviewedTransaction = reviewedTransaction
			return review(&state, executionSummary: preview.analyzedManifestToReview)
				.concatenate(with: determineFeePayer(state, reviewedTransaction: reviewedTransaction))

		case let .updateSections(sections):
			guard let sections else {
				state.destination = .rawTransactionAlert(.rawTransaction)
				return showRawTransaction(&state)
			}

			state.withdrawals = sections.withdrawals
			state.dAppsUsed = sections.dAppsUsed
			state.contributingToPools = sections.contributingToPools
			state.redeemingFromPools = sections.redeemingFromPools
			state.stakingToValidators = sections.stakingToValidators
			state.unstakingFromValidators = sections.unstakingFromValidators
			state.claimingFromValidators = sections.claimingFromValidators
			state.deposits = sections.deposits
			state.accountDepositSetting = sections.accountDepositSetting
			state.accountDepositExceptions = sections.accountDepositExceptions
			state.proofs = sections.proofs

			return .none

		case let .buildTransactionIntentResult(.success(intent)):
			guard let reviewedTransaction = state.reviewedTransaction else {
				return .none
			}

			if reviewedTransaction.transactionSigners.notaryIsSignatory {
				let notaryKey = state.ephemeralNotaryPrivateKey

				/// Silently sign the transaction with notary keys.
				return .run { send in
					await send(.internal(.notarizeResult(TaskResult {
						try await transactionClient.notarizeTransaction(.init(
							intentSignatures: [],
							transactionIntent: intent,
							notary: notaryKey
						))
					})))
				}
			}

			state.destination = .signing(.init(
				factorsLeftToSignWith: reviewedTransaction.signingFactors,
				signingPurposeWithPayload: .signTransaction(
					ephemeralNotaryPrivateKey: state.ephemeralNotaryPrivateKey,
					intent,
					origin: state.signTransactionPurpose
				)
			))
			return .none

		case let .notarizeResult(.success(notarizedTX)):
			state.destination = .submitting(.init(
				notarizedTX: notarizedTX,
				inProgressDismissalDisabled: state.waitsForTransactionToBeComitted,
				route: state.p2pRoute
			))
			return .none

		case let .buildTransactionIntentResult(.failure(error)),
		     let .notarizeResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .determineFeePayerResult(.success(selectionResult)):
			guard var reviewedTransaction = state.reviewedTransaction else {
				assertionFailure("Expected to have reviewed transaction")
				return .none
			}

			reviewedTransaction.feePayer = .success(selectionResult?.payer)

			if let selectionResult {
				reviewedTransaction.transactionFee = selectionResult.updatedFee
				reviewedTransaction.transactionSigners = selectionResult.transactionSigners
				reviewedTransaction.signingFactors = selectionResult.signingFactors
			}

			state.reviewedTransaction = reviewedTransaction
			state.networkFee?.reviewedTransaction = reviewedTransaction

			if reviewedTransaction.isNonConforming {
				return showRawTransaction(&state)
			}
			return .none

		case let .determineFeePayerResult(.failure(error)):
			errorQueue.schedule(error)
			state.reviewedTransaction?.feePayer = .success(nil)
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .customizeGuarantees(.delegate(.applyGuarantees(guaranteeStates))):
			for guaranteeState in guaranteeStates {
				state.applyGuarantee(guaranteeState.guarantee, transferID: guaranteeState.id)
			}

			return .none

		case let .customizeFees(.delegate(.updated(reviewedTransaction))):
			state.reviewedTransaction = reviewedTransaction
			state.networkFee = .init(reviewedTransaction: reviewedTransaction)
			state.printFeePayerInfo()
			return .none

		case .signing(.delegate(.cancelSigning)):
			loggerGlobal.notice("Cancelled signing")
			return resetToApprovable(&state)

		case .signing(.delegate(.failedToSign)):
			loggerGlobal.error("Failed sign tx")
			return resetToApprovable(&state)

		case let .signing(.delegate(.finishedSigning(.signTransaction(notarizedTX, origin: _)))):
			state.destination = .submitting(.init(
				notarizedTX: notarizedTX,
				inProgressDismissalDisabled: state.waitsForTransactionToBeComitted,
				route: state.p2pRoute
			))
			return .none

		case .signing(.delegate(.finishedSigning(.signAuth))):
			state.canApproveTX = true
			assertionFailure("Did not expect to have sign auth data...")
			return .none

		case let .submitting(.delegate(.submittedButNotCompleted(txID))):
			return .send(.delegate(.signedTXAndSubmittedToGateway(txID)))

		case .submitting(.delegate(.failedToSubmit)):
			return .send(.delegate(.failed(.failedToSubmit)))

		case let .submitting(.delegate(.committedSuccessfully(txID))):
			state.destination = nil
			return delayedShortEffect(for: .delegate(.transactionCompleted(txID)))

		case .submitting(.delegate(.manuallyDismiss)):
			// This is used when the close button is pressed, we have to manually
			state.destination = nil
			return delayedShortEffect(for: .delegate(.dismiss))

		default:
			return .none
		}
	}

	func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		if case .signing = state.destination {
			loggerGlobal.notice("Cancelled signing")
			return resetToApprovable(&state)
		} else if case .submitting = state.destination {
			// This is used when tapping outside the Submitting sheet, no need to set destination to nil
			return delayedShortEffect(for: .delegate(.dismiss))
		}

		return .none
	}
}

extension AlertState<TransactionReview.Destination.Action.RawTransactionAlert> {
	static var rawTransaction: AlertState {
		AlertState {
			TextState(L10n.TransactionReview.NonConformingManifestWarning.title)
		} actions: {
			ButtonState(action: .continueTapped) {
				TextState(L10n.Common.continue)
			}
		} message: {
			TextState(L10n.TransactionReview.NonConformingManifestWarning.message)
		}
	}
}

extension Collection<InteractionReviewCommon.Account.State> {
	var customizableGuarantees: [TransactionReviewGuarantee.State] {
		flatMap { account in
			account.transfers.compactMap { .init(account: account.account, transfer: $0) }
		}
	}
}

extension TransactionReview {
	// MARK: - TransferType
	enum TransferType {
		case exact
		case estimated(instructionIndex: UInt64)
	}

	func review(_ state: inout State, executionSummary: ExecutionSummary) -> Effect<Action> {
		guard let reviewedTransaction = state.reviewedTransaction else {
			assertionFailure("Bad implementation, expected `analyzedManifestToReview`")
			return .none
		}
		guard let networkID = state.networkID else {
			assertionFailure("Bad implementation, expected `networkID`")
			return .none
		}

		state.networkFee = .init(reviewedTransaction: reviewedTransaction)

		return .run { send in
			let sections = try await sections(for: executionSummary, networkID: networkID)
			await send(.internal(.updateSections(sections)))
		} catch: { error, send in
			loggerGlobal.error("Failed to extract transaction content, error: \(error)")
			// FIXME: propagate/display error?
			await send(.internal(.updateSections(nil)))
		}
	}

	func showRawTransaction(_ state: inout State) -> Effect<Action> {
		do {
			let manifest = try transactionManifestWithWalletInstructionsAdded(state)
			state.displayMode = .raw(manifest.instructionsString)
		} catch {
			errorQueue.schedule(error)
		}
		return .none
	}

	func transactionManifestWithWalletInstructionsAdded(_ state: State) throws -> TransactionManifest {
		guard let reviewedTransaction = state.reviewedTransaction else {
			struct MissingReviewedTransaction: Error {}
			throw MissingReviewedTransaction()
		}

		var manifest = reviewedTransaction.transactionManifest
		if case let .success(feePayerAccount) = reviewedTransaction.feePayer.unwrap()?.account {
			manifest = reviewedTransaction.transactionManifest.modify(
				lockFee: reviewedTransaction.transactionFee.totalFee.lockFee,
				addressOfFeePayer: feePayerAccount.address
			)
		}

		return try manifest.modify(addGuarantees: state.allGuarantees)
	}

	func determineFeePayer(_ state: State, reviewedTransaction: ReviewedTransaction) -> Effect<Action> {
		if reviewedTransaction.transactionFee.totalFee.lockFee == .zero {
			.send(.internal(.determineFeePayerResult(.success(nil))))
		} else {
			.run { send in
				let result = await TaskResult {
					try await transactionClient.determineFeePayer(.init(
						networkId: reviewedTransaction.networkID,
						transactionFee: reviewedTransaction.transactionFee,
						transactionSigners: reviewedTransaction.transactionSigners,
						signingFactors: reviewedTransaction.signingFactors,
						signingPurpose: .signTransaction(state.signTransactionPurpose),
						manifest: reviewedTransaction.transactionManifest
					))
				}

				await send(.internal(.determineFeePayerResult(result)))
			}
		}
	}

	func resourceDetailsEffect(
		state: inout State,
		resource: OnLedgerEntity.Resource,
		details: ResourceBalance.Details,
		nft: OnLedgerEntity.NonFungibleToken? = nil
	) -> Effect<Action> {
		switch details {
		case let .fungible(details):
			state.destination = .fungibleTokenDetails(.init(
				resourceAddress: resource.resourceAddress,
				resource: .success(resource),
				ownedFungibleResource: .init(
					resourceAddress: resource.resourceAddress,
					atLedgerState: resource.atLedgerState,
					amount: details.amount,
					metadata: resource.metadata
				),
				isXRD: details.isXRD
			))

		case let .nonFungible(details):
			state.destination = .nonFungibleTokenDetails(.init(
				resourceAddress: resource.resourceAddress,
				resourceDetails: .success(resource),
				token: details,
				ledgerState: resource.atLedgerState
			))

		case let .liquidStakeUnit(details):
			state.destination = .lsuDetails(.init(
				validator: details.validator,
				stakeUnitResource: .init(resource: details.resource, amount: .init(nominalAmount: details.amount)),
				xrdRedemptionValue: details.worth
			))

		case let .poolUnit(details):
			state.destination = .poolUnitDetails(.init(resourcesDetails: details.details))

		case let .stakeClaimNFT(details):
			state.destination = .nonFungibleTokenDetails(.init(
				resourceAddress: resource.resourceAddress,
				resourceDetails: .success(resource),
				token: nft,
				ledgerState: resource.atLedgerState,
				stakeClaim: details.stakeClaimTokens.stakeClaims.first,
				isClaimStakeEnabled: false
			))
		}

		return .none
	}
}

// MARK: - FailedToAddLockFee
struct FailedToAddLockFee: LocalizedError {
	let underlyingError: Swift.Error
	init(underlyingError: Swift.Error) {
		self.underlyingError = underlyingError
	}

	var errorDescription: String? {
		#if DEBUG
		L10n.Error.TransactionFailure.failedToAddLockFee + "\n[DEBUG ONLY]: \(String(describing: underlyingError))"
		#else
		L10n.Error.TransactionFailure.failedToAddLockFee
		#endif
	}
}

// MARK: - FailedToAddGuarantee
struct FailedToAddGuarantee: LocalizedError {
	let underlyingError: Swift.Error
	init(underlyingError: Swift.Error) {
		self.underlyingError = underlyingError
	}

	var errorDescription: String? {
		#if DEBUG
		L10n.Error.TransactionFailure.failedToAddGuarantee + "\n[DEBUG ONLY]: \(String(describing: underlyingError))"
		#else
		L10n.Error.TransactionFailure.failedToAddGuarantee
		#endif
	}
}

extension TransactionReview {
	func resetToApprovable(
		_ state: inout State,
		shouldNilDestination: Bool = true
	) -> Effect<Action> {
		if shouldNilDestination {
			state.destination = nil
		}
		state.canApproveTX = true
		state.resetSlider()
		return .none
	}
}

// MARK: - TransactionReview.DappEntity
extension TransactionReview {
	struct DappEntity: Sendable, Identifiable, Hashable {
		let id: DappDefinitionAddress
		let metadata: OnLedgerEntity.Metadata
	}
}

extension ResourceBalance {
	/// The guarantee, for a fungible resource
	var fungibleGuarantee: TransactionGuarantee? {
		get {
			switch details {
			case let .fungible(fungible):
				fungible.guarantee
			case let .liquidStakeUnit(liquidStakeUnit):
				liquidStakeUnit.guarantee
			case let .poolUnit(poolUnit):
				poolUnit.guarantee
			case .nonFungible, .stakeClaimNFT:
				nil
			}
		}
		set {
			switch details {
			case var .fungible(fungible):
				fungible.guarantee = newValue
				details = .fungible(fungible)
			case var .liquidStakeUnit(liquidStakeUnit):
				liquidStakeUnit.guarantee = newValue
				details = .liquidStakeUnit(liquidStakeUnit)
			case var .poolUnit(poolUnit):
				poolUnit.guarantee = newValue
				details = .poolUnit(poolUnit)
			case .nonFungible, .stakeClaimNFT:
				return
			}
		}
	}

	/// The transferred amount, for a fungible resource
	var fungibleTransferAmount: Decimal192? {
		switch details {
		case let .fungible(fungible):
			fungible.amount.nominalAmount
		case let .liquidStakeUnit(liquidStakeUnit):
			liquidStakeUnit.amount
		case let .poolUnit(poolUnit):
			poolUnit.details.poolUnitResource.amount.nominalAmount
		case .nonFungible, .stakeClaimNFT:
			nil
		}
	}
}

extension TransactionReview.State {
	var allGuarantees: [TransactionGuarantee] {
		deposits?.accounts.flatMap { $0.transfers.compactMap(\.fungibleGuarantee) } ?? []
	}

	mutating func applyGuarantee(
		_ updated: TransactionGuarantee,
		transferID: InteractionReviewCommon.Transfer.ID
	) {
		guard let accountID = accountID(for: transferID) else { return }
		deposits?.accounts[id: accountID]?.transfers[id: transferID]?.fungibleGuarantee = updated
	}

	private func accountID(for transferID: InteractionReviewCommon.Transfer.ID) -> AccountAddress? {
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

extension [InteractionReviewCommon.ReviewAccount] {
	struct MissingUserAccountError: Error {}

	func account(for accountAddress: AccountAddress) throws -> InteractionReviewCommon.ReviewAccount {
		guard let account = first(where: { $0.address == accountAddress }) else {
			loggerGlobal.error("Can't find address that was specified for transfer")
			throw MissingUserAccountError()
		}

		return account
	}
}

extension Collection where Element: Equatable {
	func count(of element: Element) -> Int {
		var count = 0
		for e in self where e == element {
			count += 1
		}
		return count
	}
}

extension ResourceIndicator {
	var transferType: TransactionReview.TransferType {
		switch self {
		case .fungible(_, .guaranteed), .nonFungible: // we don't yet handle NFT predicted amounts
			.exact
		case let .fungible(_, .predicted(predictedAmount)):
			.estimated(instructionIndex: predictedAmount.instructionIndex)
		}
	}
}

// MARK: - TransactionReviewFailure
struct TransactionReviewFailure: LocalizedError {
	let underylying: Swift.Error
	var errorDescription: String? {
		let additionalInfo = if case TransactionFailure.failedToPrepareTXReview(.oneOfRecevingAccountsDoesNotAllowDeposits) = underylying {
			"\n\n" + L10n.Error.TransactionFailure.doesNotAllowThirdPartyDeposits
		} else {
			""
		}

		let debugInfo = {
			// https://rdxworks.slack.com/archives/C031A0V1A1W/p1694087946050189?thread_ts=1694085688.749539&cid=C031A0V1A1W
			#if DEBUG
			"\n[DEBUG] Underlying error: \(String(describing: underylying))"
			#else
			""
			#endif
		}()

		return L10n.Error.TransactionFailure.reviewFailure + additionalInfo + debugInfo
	}
}

// MARK: - ReviewedTransaction
struct ReviewedTransaction: Hashable, Sendable {
	let transactionManifest: TransactionManifest
	let networkID: NetworkID
	var feePayer: Loadable<FeePayerCandidate?> = .idle

	var transactionFee: TransactionFee
	var transactionSigners: TransactionSigners
	var signingFactors: SigningFactors

	let accountWithdraws: [AccountAddress: [ResourceIndicator]]
	let accountDeposits: [AccountAddress: [ResourceIndicator]]
	let isNonConforming: Bool
}

// MARK: - FeePayerValidationOutcome
enum FeePayerValidationOutcome: Sendable, Hashable {
	case needsFeePayer
	case insufficientBalance
	case valid(Details?)

	enum Details: Sendable {
		case introducesNewAccount
		case feePayerSuperfluous
	}

	var isValid: Bool {
		guard case .valid = self else { return false }
		return true
	}
}

extension ReviewedTransaction {
	var involvedAccounts: Set<AccountAddress> {
		Set(accountWithdraws.keys)
			.union(accountDeposits.keys)
			.union(transactionManifest.summary.addressesOfAccountsRequiringAuth)
	}

	var feePayingValidation: Loadable<FeePayerValidationOutcome> {
		feePayer.map(validateFeePayer)
	}

	func validateFeePayer(_ candidate: FeePayerCandidate?) -> FeePayerValidationOutcome {
		guard let candidate else {
			if transactionFee.totalFee.lockFee == .zero {
				// No fee is required - no fee payer needed
				return .valid(.feePayerSuperfluous)
			} else {
				// Fee is required, but no fee payer selected - invalid
				return .needsFeePayer
			}
		}

		let xrdAddress: ResourceAddress = .xrd(on: networkID)
		let feePayerWithdraws = accountWithdraws[candidate.account.address] ?? []
		let xrdTransfer: Decimal192 = feePayerWithdraws.reduce(.zero) { partialResult, resource in
			if case let .fungible(resourceAddress, indicator) = resource, resourceAddress == xrdAddress {
				return partialResult + indicator.amount
			}
			return partialResult
		}

		let totalAmountNeeded = xrdTransfer + transactionFee.totalFee.lockFee

		guard candidate.xrdBalance >= totalAmountNeeded else {
			// Insufficient balance to pay for withdraws and transaction fee
			return .insufficientBalance
		}

		if !involvedAccounts.contains(candidate.account.address) {
			return .valid(.introducesNewAccount)
		} else {
			return .valid(nil)
		}
	}
}

#if DEBUG
func printSigners(_ reviewedTransaction: ReviewedTransaction) {
	for (factorSourceKind, signingFactorsOfKind) in reviewedTransaction.signingFactors {
		loggerGlobal.debug("🔮 ~~~ SIGNINGFACTORS OF KIND: \(factorSourceKind) #\(signingFactorsOfKind.count) many: ~~~")
		for signingFactor in signingFactorsOfKind {
			let factorSource = signingFactor.factorSource
			loggerGlobal.debug("\t🔮 == Signers for factorSource: \(factorSource.id): ==")
			for signer in signingFactor.signers {
				let entity = signer.entity
				loggerGlobal.debug("\t\t🔮 * Entity: \(entity.displayName): *")
				for factorInstance in signer.factorInstancesRequiredToSign {
					loggerGlobal.debug("\t\t\t🔮 * FactorInstance: \(String(describing: factorInstance.derivationPath)) \(factorInstance.publicKey)")
				}
			}
		}
	}
}
#endif // DEBUG

#if DEBUG
extension TransactionSigners {
	func intentSignerEntitiesNonEmptyOrNil() -> NonEmpty<OrderedSet<AccountOrPersona>>? {
		switch intentSigning {
		case let .intentSigners(signers) where !signers.isEmpty:
			NonEmpty(rawValue: OrderedSet(signers))
		default:
			nil
		}
	}
}
#endif
