import ComposableArchitecture
import SwiftUI

// MARK: - TransactionReview
public struct TransactionReview: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var displayMode: DisplayMode = .review

		public let nonce: Nonce
		public let unvalidatedManifest: UnvalidatedTransactionManifest
		public let message: Message
		public let signTransactionPurpose: SigningPurpose.SignTransactionPurpose
		public let waitsForTransactionToBeComitted: Bool
		public let isWalletTransaction: Bool
		public let proposingDappMetadata: DappMetadata.Ledger?

		public var networkID: NetworkID? { reviewedTransaction?.networkID }

		public var reviewedTransaction: ReviewedTransaction? = nil

		public var withdrawals: TransactionReviewAccounts.State? = nil
		public var dAppsUsed: TransactionReviewDappsUsed.State? = nil
		public var contributingToPools: TransactionReviewPools.State? = nil
		public var redeemingFromPools: TransactionReviewPools.State? = nil
		public var deposits: TransactionReviewAccounts.State? = nil

		public var stakingToValidators: ValidatorsState? = nil
		public var unstakingFromValidators: ValidatorsState? = nil
		public var claimingFromValidators: ValidatorsState? = nil

		public var accountDepositSetting: DepositSettingState? = nil
		public var accountDepositExceptions: DepositExceptionsState? = nil

		public var proofs: TransactionReviewProofs.State? = nil
		public var networkFee: TransactionReviewNetworkFee.State? = nil
		public let ephemeralNotaryPrivateKey: Curve25519.Signing.PrivateKey
		public var canApproveTX: Bool = true
		var sliderResetDate: Date = .now

		@PresentationState
		public var destination: Destination.State? = nil

		public func printFeePayerInfo(line: UInt = #line, function: StaticString = #function) {
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

		public mutating func resetSlider() {
			sliderResetDate = .now
		}

		public init(
			unvalidatedManifest: UnvalidatedTransactionManifest,
			nonce: Nonce,
			signTransactionPurpose: SigningPurpose.SignTransactionPurpose,
			message: Message,
			ephemeralNotaryPrivateKey: Curve25519.Signing.PrivateKey = .init(),
			waitsForTransactionToBeComitted: Bool = false,
			isWalletTransaction: Bool,
			proposingDappMetadata: DappMetadata.Ledger?
		) {
			self.nonce = nonce
			self.unvalidatedManifest = unvalidatedManifest
			self.signTransactionPurpose = signTransactionPurpose
			self.message = message
			self.ephemeralNotaryPrivateKey = ephemeralNotaryPrivateKey
			self.waitsForTransactionToBeComitted = waitsForTransactionToBeComitted
			self.isWalletTransaction = isWalletTransaction
			self.proposingDappMetadata = proposingDappMetadata
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

	public enum ChildAction: Sendable, Equatable {
		case withdrawals(TransactionReviewAccounts.Action)
		case deposits(TransactionReviewAccounts.Action)
		case dAppsUsed(TransactionReviewDappsUsed.Action)
		case contributingToPools(TransactionReviewPools.Action)
		case redeemingFromPools(TransactionReviewPools.Action)
		case proofs(TransactionReviewProofs.Action)
		case networkFee(TransactionReviewNetworkFee.Action)
	}

	public enum InternalAction: Sendable, Equatable {
		case previewLoaded(TaskResult<TransactionToReview>)
		case updateSections(TransactionReview.Sections?)
		case buildTransactionItentResult(TaskResult<TransactionIntent>)
		case notarizeResult(TaskResult<NotarizeTransactionResponse>)
		case determineFeePayerResult(TaskResult<FeePayerSelectionResult?>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case failed(TransactionFailure)
		case signedTXAndSubmittedToGateway(TXID)
		case transactionCompleted(TXID)
		case dismiss
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
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

		public enum Action: Sendable, Equatable {
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

			public enum RawTransactionAlert: Sendable, Equatable {
				case continueTapped
			}
		}

		public var body: some ReducerOf<Self> {
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
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient
	@Dependency(\.pasteboardClient) var pasteboardClient

	public init() {}

	public var body: some ReducerOf<Self> {
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
			.ifLet(\.contributingToPools, action: /Action.child .. ChildAction.contributingToPools) {
				TransactionReviewPools()
			}
			.ifLet(\.redeemingFromPools, action: /Action.child .. ChildAction.redeemingFromPools) {
				TransactionReviewPools()
			}
			.ifLet(\.withdrawals, action: /Action.child .. ChildAction.withdrawals) {
				TransactionReviewAccounts()
			}
			.ifLet(\.proofs, action: /Action.child .. ChildAction.proofs) {
				TransactionReviewProofs()
			}
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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
			case .review:
				return showRawTransaction(&state)
			case .raw:
				state.displayMode = .review
				return .none
			}

		case let .copyRawTransactionTapped:
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
					await send(.internal(.buildTransactionItentResult(TaskResult {
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

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .withdrawals(.delegate(.showAsset(transfer, token))),
		     let .deposits(.delegate(.showAsset(transfer, token))):
			switch transfer.details {
			case let .fungible(details):
				state.destination = .fungibleTokenDetails(
					.init(
						resourceAddress: transfer.resource.resourceAddress,
						resource: .success(transfer.resource),
						isXRD: details.isXRD
					)
				)

			case let .nonFungible(details):
				state.destination = .nonFungibleTokenDetails(.init(
					resourceAddress: transfer.resource.resourceAddress,
					resourceDetails: .success(transfer.resource),
					token: details,
					ledgerState: transfer.resource.atLedgerState
				))

			case let .liquidStakeUnit(details):
				state.destination = .lsuDetails(.init(
					validator: details.validator,
					stakeUnitResource: .init(resource: details.resource, amount: details.amount),
					xrdRedemptionValue: details.worth
				))

				return .none

			case let .poolUnit(details):
				state.destination = .poolUnitDetails(.init(resourcesDetails: details.details))

			case let .stakeClaimNFT(details):
				state.destination = .nonFungibleTokenDetails(.init(
					resourceAddress: transfer.resource.resourceAddress,
					resourceDetails: .success(transfer.resource),
					token: token,
					ledgerState: transfer.resource.atLedgerState
				))
			}

			return .none

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
			state.destination = .customizeGuarantees(.init(guarantees: .init(uniqueElements: guarantees)))

			return .none

		case .networkFee(.delegate(.showCustomizeFees)):
			guard let reviewedTransaction = state.reviewedTransaction else {
				return .none
			}
			state.destination = .customizeFees(.init(
				reviewedTransaction: reviewedTransaction,
				manifestSummary: reviewedTransaction.transactionManifest.summary(networkId: reviewedTransaction.networkID.rawValue),
				signingPurpose: .signTransaction(state.signTransactionPurpose)
			))
			return .none

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
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
				accountWithdraws: preview.analyzedManifestToReview.accountWithdraws,
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

		case let .buildTransactionItentResult(.success(intent)):
			guard let reviewedTransaction = state.reviewedTransaction else {
				return .none
			}

			if reviewedTransaction.transactionSigners.notaryIsSignatory {
				let notaryKey: SLIP10.PrivateKey = .curve25519(state.ephemeralNotaryPrivateKey)

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
			state.destination = .submitting(.init(notarizedTX: notarizedTX, inProgressDismissalDisabled: state.waitsForTransactionToBeComitted))
			return .none

		case let .buildTransactionItentResult(.failure(error)),
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
			assertionFailure("Failed to determine fee payer \(error)")
			state.reviewedTransaction?.feePayer = .success(nil)
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
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
				inProgressDismissalDisabled: state.waitsForTransactionToBeComitted
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

		case .fungibleTokenDetails(.delegate(.dismiss)):
			state.destination = nil
			return .none

		default:
			return .none
		}
	}

	public func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
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

extension Collection<TransactionReviewAccount.State> {
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

	public func addingGuarantees(
		to manifest: TransactionManifest,
		guarantees: [TransactionClient.Guarantee]
	) throws -> TransactionManifest {
		guard !guarantees.isEmpty else { return manifest }

		var manifest = manifest

		/// Will be increased with each added guarantee to account for the difference in indexes from the initial manifest.
		var indexInc = 1 // LockFee was added, start from 1
		for guarantee in guarantees {
			let decimalplaces = guarantee.resourceDivisibility.map(UInt.init) ?? RETDecimal.maxDivisibility
			let guaranteeInstruction: Instruction = try .assertWorktopContains(
				resourceAddress: guarantee.resourceAddress.intoEngine(),
				amount: guarantee.amount.rounded(decimalPlaces: decimalplaces)
			)

			manifest = try manifest.withInstructionAdded(guaranteeInstruction, at: Int(guarantee.instructionIndex) + indexInc)

			indexInc += 1
		}
		return manifest
	}

	func showRawTransaction(_ state: inout State) -> Effect<Action> {
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
		guard let reviewedTransaction = state.reviewedTransaction else {
			struct MissingReviewedTransaction: Error {}
			throw MissingReviewedTransaction()
		}

		var manifest = reviewedTransaction.transactionManifest
		if case let .success(feePayerAccount) = reviewedTransaction.feePayer.unwrap()?.account {
			do {
				manifest = try reviewedTransaction.transactionManifest.withLockFeeCallMethodAdded(
					address: feePayerAccount.address.asGeneral,
					fee: reviewedTransaction.transactionFee.totalFee.lockFee
				)
			} catch {
				loggerGlobal.error("Failed to add lock fee, error: \(error)")
				throw FailedToAddLockFee(underlyingError: error)
			}
		}
		do {
			return try addingGuarantees(to: manifest, guarantees: state.allGuarantees)
		} catch {
			loggerGlobal.error("Failed to add guarantee, error: \(error)")
			throw FailedToAddGuarantee(underlyingError: error)
		}
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
}

// MARK: - FailedToAddLockFee
public struct FailedToAddLockFee: LocalizedError {
	public let underlyingError: Swift.Error
	public init(underlyingError: Swift.Error) {
		self.underlyingError = underlyingError
	}

	public var errorDescription: String? {
		#if DEBUG
		L10n.Error.TransactionFailure.failedToAddLockFee + "\n[DEBUG ONLY]: \(String(describing: underlyingError))"
		#else
		L10n.Error.TransactionFailure.failedToAddLockFee
		#endif
	}
}

// MARK: - FailedToAddGuarantee
public struct FailedToAddGuarantee: LocalizedError {
	public let underlyingError: Swift.Error
	public init(underlyingError: Swift.Error) {
		self.underlyingError = underlyingError
	}

	public var errorDescription: String? {
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

extension ResourceOrNonFungible {
	func resourceAddress() throws -> ResourceAddress {
		switch self {
		case let .resource(address):
			try address.asSpecific()
		case let .nonFungible(globalID):
			try globalID.resourceAddress().asSpecific()
		}
	}
}

// MARK: Useful types

extension TransactionReview {
	public struct ProofEntity: Sendable, Identifiable, Hashable {
		public let id: ResourceAddress
		public let metadata: OnLedgerEntity.Metadata
	}

	public struct DappEntity: Sendable, Identifiable, Hashable {
		public let id: DappDefinitionAddress
		public let metadata: OnLedgerEntity.Metadata
		public let isAuthorized: Bool
	}

	public enum Account: Sendable, Hashable {
		case user(Profile.Network.Account)
		case external(AccountAddress, approved: Bool)

		var address: AccountAddress {
			switch self {
			case let .user(account):
				account.address
			case let .external(address, _):
				address
			}
		}

		var isApproved: Bool {
			switch self {
			case .user:
				false
			case let .external(_, approved):
				approved
			}
		}
	}

	public struct Transfer: Sendable, Identifiable, Hashable {
		public typealias ID = Tagged<Self, UUID>

		public let id = ID()
		public let resource: OnLedgerEntity.Resource
		public var details: Details

		public enum Details: Sendable, Hashable {
			case fungible(Fungible)
			case nonFungible(NonFungible)
			case poolUnit(PoolUnit)
			case liquidStakeUnit(LiquidStakeUnit)
			case stakeClaimNFT(StakeClaimNFT)

			public struct Fungible: Sendable, Hashable {
				public let isXRD: Bool
				public let amount: RETDecimal
				public var guarantee: TransactionClient.Guarantee?
			}

			public struct LiquidStakeUnit: Sendable, Hashable {
				public let resource: OnLedgerEntity.Resource
				public let amount: RETDecimal
				public let worth: RETDecimal
				public let validator: OnLedgerEntity.Validator
				public var guarantee: TransactionClient.Guarantee?
			}

			public typealias NonFungible = OnLedgerEntity.NonFungibleToken
			public typealias StakeClaimNFT = StakeClaimResourceView.ViewState

			public struct PoolUnit: Sendable, Hashable {
				public let details: OnLedgerEntitiesClient.OwnedResourcePoolDetails
				public var guarantee: TransactionClient.Guarantee?
			}
		}

		/// The guarantee, for a fungible resource
		public var fungibleGuarantee: TransactionClient.Guarantee? {
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
		public var fungibleTransferAmount: RETDecimal? {
			switch details {
			case let .fungible(fungible):
				fungible.amount
			case let .liquidStakeUnit(liquidStakeUnit):
				liquidStakeUnit.amount
			case let .poolUnit(poolUnit):
				poolUnit.details.poolUnitResource.amount
			case .nonFungible, .stakeClaimNFT:
				nil
			}
		}

		public var isXRD: Bool {
			guard case let .fungible(fungible) = details else {
				return false
			}

			return fungible.isXRD
		}
	}
}

extension TransactionReview.State {
	public var allGuarantees: [TransactionClient.Guarantee] {
		deposits?.accounts.flatMap { $0.transfers.compactMap(\.fungibleGuarantee) } ?? []
	}

	public mutating func applyGuarantee(_ updated: TransactionClient.Guarantee, transferID: TransactionReview.Transfer.ID) {
		guard let accountID = accountID(for: transferID) else { return }
		deposits?.accounts[id: accountID]?.transfers[id: transferID]?.fungibleGuarantee = updated
	}

	private func accountID(for transferID: TransactionReview.Transfer.ID) -> AccountAddress? {
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
public struct TransactionReviewFailure: LocalizedError {
	public let underylying: Swift.Error
	public var errorDescription: String? {
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
public struct ReviewedTransaction: Hashable, Sendable {
	let transactionManifest: TransactionManifest
	let networkID: NetworkID
	var feePayer: Loadable<FeePayerCandidate?> = .idle

	var transactionFee: TransactionFee
	var transactionSigners: TransactionSigners
	var signingFactors: SigningFactors

	let accountWithdraws: [String: [ResourceIndicator]]
	let isNonConforming: Bool
}

// MARK: - FeeValidationOutcome
enum FeeValidationOutcome {
	case valid
	case needsFeePayer
	case insufficientBalance
}

extension ReviewedTransaction {
	var feePayingValidation: Loadable<FeeValidationOutcome> {
		feePayer.map { selected in
			guard let feePayer = selected,
			      let feePayerWithdraws = accountWithdraws[feePayer.account.address.address]
			else {
				return selected.validateBalance(forFee: transactionFee)
			}

			let xrdAddress = knownAddresses(networkId: networkID.rawValue).resourceAddresses.xrd

			let xrdTotalTransfer: RETDecimal = feePayerWithdraws.reduce(.zero) { partialResult, resource in
				if case let .fungible(resourceAddress, indicator) = resource, resourceAddress == xrdAddress {
					return (try? partialResult.add(other: indicator.amount)) ?? partialResult
				}
				return partialResult
			}

			let total = xrdTotalTransfer + transactionFee.totalFee.lockFee

			guard feePayer.xrdBalance >= total else {
				// Insufficient balance to pay for withdraws and transaction fee
				return .insufficientBalance
			}

			return .valid
		}
	}
}

extension FeePayerCandidate? {
	func validateBalance(forFee transactionFee: TransactionFee) -> FeeValidationOutcome {
		if transactionFee.totalFee.lockFee == .zero {
			// If no fee is required - valid
			return .valid
		}

		guard let self else {
			// If fee is required, but no fee payer selected - invalid
			return .needsFeePayer
		}

		guard self.xrdBalance >= transactionFee.totalFee.lockFee else {
			// If insufficient balance - invalid
			return .insufficientBalance
		}

		return .valid
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
	func intentSignerEntitiesNonEmptyOrNil() -> NonEmpty<OrderedSet<EntityPotentiallyVirtual>>? {
		switch intentSigning {
		case let .intentSigners(signers) where !signers.isEmpty:
			NonEmpty(rawValue: OrderedSet(signers))
		default:
			nil
		}
	}
}
#endif
