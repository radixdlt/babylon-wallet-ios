import ComposableArchitecture
import SwiftUI

// MARK: - TransactionReview
struct TransactionReview: Sendable, FeatureReducer {
	typealias Common = InteractionReview

	struct State: Sendable, Hashable {
		var displayMode: Common.DisplayMode = .detailed

		let nonce: Nonce
		let unvalidatedManifest: UnvalidatedTransactionManifest
		let message: Message
		let signTransactionPurpose: SigningPurpose.SignTransactionPurpose
		let interactionId: WalletInteractionId
		let proposingDappMetadata: DappMetadata.Ledger?
		let p2pRoute: P2P.Route

		var networkID: NetworkID? { reviewedTransaction?.networkID }

		var reviewedTransaction: ReviewedTransaction? = nil

		var sections: Common.Sections.State = .init(kind: .transaction)

		var proofs: Common.Proofs.State? = nil
		var networkFee: TransactionReviewNetworkFee.State? = nil
		let ephemeralNotaryPrivateKey: Curve25519.Signing.PrivateKey
		var canApproveTX: Bool = true
		var sliderResetDate: Date = .now

		var waitsForTransactionToBeComitted: Bool {
			interactionId.isWalletAccountDepositSettingsInteraction || interactionId.isWalletAccountDeleteInteraction
		}

		var isWalletTransaction: Bool {
			interactionId.isWalletInteraction
		}

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
			interactionId: WalletInteractionId,
			proposingDappMetadata: DappMetadata.Ledger?,
			p2pRoute: P2P.Route
		) {
			self.nonce = nonce
			self.unvalidatedManifest = unvalidatedManifest
			self.signTransactionPurpose = signTransactionPurpose
			self.message = message
			self.ephemeralNotaryPrivateKey = ephemeralNotaryPrivateKey
			self.interactionId = interactionId
			self.proposingDappMetadata = proposingDappMetadata
			self.p2pRoute = p2pRoute
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case showRawTransactionTapped
		case approvalSliderSlid
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case sections(Common.Sections.Action)
		case proofs(Common.Proofs.Action)
		case networkFee(TransactionReviewNetworkFee.Action)
	}

	enum InternalAction: Sendable, Equatable {
		case previewLoaded(TaskResult<TransactionToReview>)
		case buildTransactionIntentResult(TaskResult<TransactionIntent>)
		case notarizeResult(TaskResult<NotarizeTransactionResponse>)
		case determineFeePayerResult(TaskResult<FeePayerSelectionResult?>)
		case resetToApprovable
	}

	enum DelegateAction: Sendable, Equatable {
		case failed(TransactionFailure)
		case signedTXAndSubmittedToGateway(TransactionIntentHash)
		case transactionCompleted(TransactionIntentHash)
		case dismiss
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case customizeGuarantees(TransactionReviewGuarantees.State)
			case submitting(SubmitTransaction.State)
			case customizeFees(CustomizeFees.State)
			case rawTransactionAlert(AlertState<Never>)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case customizeGuarantees(TransactionReviewGuarantees.Action)
			case submitting(SubmitTransaction.Action)
			case customizeFees(CustomizeFees.Action)
			case rawTransactionAlert(Never)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.customizeGuarantees, action: \.customizeGuarantees) {
				TransactionReviewGuarantees()
			}
			Scope(state: \.customizeFees, action: \.customizeFees) {
				CustomizeFees()
			}
			Scope(state: \.submitting, action: \.submitting) {
				SubmitTransaction()
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

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.sections, action: \.child.sections) {
			Common.Sections()
		}
		Reduce(core)
			.ifLet(\.networkFee, action: \.child.networkFee) {
				TransactionReviewNetworkFee()
			}
			.ifLet(\.proofs, action: \.child.proofs) {
				Common.Proofs()
			}
			.ifLet(destinationPath, action: \.destination) {
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
		case let .sections(.internal(.setSections(sections))):
			state.proofs = sections?.proofs
			return .none

		case let .sections(.delegate(delegateAction)):
			switch delegateAction {
			case .failedToResolveSections:
				state.destination = .rawTransactionAlert(.rawTransaction)
				return showRawTransaction(&state)

			case let .showCustomizeGuarantees(guarantees):
				state.destination = .customizeGuarantees(.init(guarantees: guarantees.asIdentified()))
				return .none
			}

		case let .proofs(.delegate(.showAsset(proof))):
			let resource = proof.resourceBalance.resource
			let details = proof.resourceBalance.details
			return .send(.child(.sections(.internal(.parent(.showResourceDetails(resource, details))))))

		case .networkFee(.delegate(.showCustomizeFees)):
			guard let reviewedTransaction = state.reviewedTransaction else {
				return .none
			}
			let summary = reviewedTransaction.transactionManifest.summary
			state.destination = .customizeFees(.init(
				reviewedTransaction: reviewedTransaction,
				manifestSummary: summary,
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
			if let txFailure = error as? TransactionFailure {
				return .send(.delegate(.failed(txFailure)))
			} else {
				return .send(.delegate(.failed(TransactionFailure.failedToPrepareTXReview(.abortedTXReview(error)))))
			}

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

		case let .buildTransactionIntentResult(.success(intent)):
			return .run { [notary = state.ephemeralNotaryPrivateKey] send in
				// TODO: Hardcoding `.primary` role, this will change once we have MFA
				let signedIntent = try await SargonOS.shared.signTransaction(transactionIntent: intent, roleKind: .primary)
				let notarizedTransaction = try await transactionClient.notarizeTransaction(
					.init(
						signedIntent: signedIntent,
						notary: notary
					)
				)
				await send(.internal(.notarizeResult(.success(notarizedTransaction))))
			} catch: { error, send in
				if let error = error as? CommonError, error == .HostInteractionAborted {
					await send(.internal(.resetToApprovable))
				} else {
					errorQueue.schedule(error)
				}
			}

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

		case .resetToApprovable:
			return resetToApprovable(&state)
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
		if case .submitting = state.destination {
			// This is used when tapping outside the Submitting sheet, no need to set destination to nil
			return delayedShortEffect(for: .delegate(.dismiss))
		}

		return .none
	}
}

extension Collection<InteractionReview.Account.State> {
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

		return .send(.child(.sections(.internal(.parent(.resolveExecutionSummary(executionSummary, networkID))))))
	}

	func showRawTransaction(_ state: inout State) -> Effect<Action> {
		do {
			let manifest = try transactionManifestWithWalletInstructionsAdded(state)
			state.displayMode = .raw(manifest: manifest.instructionsString)
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
						manifest: reviewedTransaction.transactionManifest,
						accountWithdraws: reviewedTransaction.accountWithdraws
					))
				}

				await send(.internal(.determineFeePayerResult(result)))
			}
		}
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
			case .nonFungible, .stakeClaimNFT, .none:
				nil
			}
		}
		set {
			guard let newValue else {
				return
			}

			switch self {
			case let .known(knownResourceBalance):
				switch knownResourceBalance.details {
				case var .fungible(fungible):
					fungible.guarantee = newValue
					fungible.amount.setGuaranteedAmount(newValue.amount)
					var known = knownResourceBalance
					known.details = .fungible(fungible)
					self = .known(known)
				case var .liquidStakeUnit(liquidStakeUnit):
					liquidStakeUnit.guarantee = newValue
					liquidStakeUnit.amount.setGuaranteedAmount(newValue.amount)
					var known = knownResourceBalance
					known.details = .liquidStakeUnit(liquidStakeUnit)
					self = .known(known)
				case var .poolUnit(poolUnit):
					poolUnit.guarantee = newValue
					poolUnit.details.poolUnitResource.amount.setGuaranteedAmount(newValue.amount)
					var known = knownResourceBalance
					known.details = .poolUnit(poolUnit)
					self = .known(known)
				case .nonFungible, .stakeClaimNFT:
					assertionFailure("Should not be possible to set guarantee")
				}
			case .unknown:
				assertionFailure("Should not be possible to set guarantee")
			}
		}
	}

	/// The transferred amount, for a fungible resource
	var fungiblePredictedTransferAmount: Decimal192? {
		switch details {
		case let .fungible(fungible):
			fungible.amount.predictedAmount?.nominalAmount
		case let .liquidStakeUnit(liquidStakeUnit):
			liquidStakeUnit.amount.predictedAmount?.nominalAmount
		case let .poolUnit(poolUnit):
			poolUnit.details.poolUnitResource.amount.predictedAmount?.nominalAmount
		case .nonFungible, .stakeClaimNFT, .none:
			nil
		}
	}
}

extension TransactionReview.State {
	var allGuarantees: [TransactionGuarantee] {
		sections.deposits?.accounts.flatMap { $0.transfers.compactMap(\.fungibleGuarantee) } ?? []
	}

	mutating func applyGuarantee(
		_ updated: TransactionGuarantee,
		transferID: InteractionReview.Transfer.ID
	) {
		guard let accountID = accountID(for: transferID) else { return }
		sections.deposits?.accounts[id: accountID]?.transfers[id: transferID]?.fungibleGuarantee = updated
	}

	private func accountID(for transferID: InteractionReview.Transfer.ID) -> AccountAddress? {
		for account in sections.deposits?.accounts ?? [] {
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

extension [InteractionReview.ReviewAccount] {
	struct MissingUserAccountError: Error {}

	func account(for accountAddress: AccountAddress) throws -> InteractionReview.ReviewAccount {
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

private extension AlertState<Never> {
	static var rawTransaction: AlertState {
		AlertState {
			TextState(L10n.TransactionReview.NonConformingManifestWarning.title)
		} actions: {
			.default(TextState(L10n.Common.continue))
		} message: {
			TextState(L10n.TransactionReview.NonConformingManifestWarning.message)
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
