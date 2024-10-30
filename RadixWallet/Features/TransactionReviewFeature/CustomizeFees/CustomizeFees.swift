import ComposableArchitecture
import SwiftUI

// MARK: - CustomizeFees
struct CustomizeFees: FeatureReducer, Sendable {
	struct State: Hashable, Sendable {
		@CasePathable
		enum CustomizationModeState: Hashable, Sendable {
			case normal(NormalFeesCustomization.State)
			case advanced(AdvancedFeesCustomization.State)
		}

		let manifestSummary: ManifestSummary
		let signingPurpose: SigningPurpose
		var reviewedTransaction: ReviewedTransaction
		var modeState: CustomizationModeState

		var feePayerAccount: Account? {
			feePayer?.account
		}

		var feePayer: FeePayerCandidate? {
			reviewedTransaction.feePayer.unwrap()?.wrappedValue
		}

		var transactionFee: TransactionFee {
			reviewedTransaction.transactionFee
		}

		var feePayingValidation: FeePayerValidationOutcome? {
			reviewedTransaction.feePayingValidation.wrappedValue
		}

		@PresentationState
		var destination: Destination.State? = nil

		init(
			reviewedTransaction: ReviewedTransaction,
			manifestSummary: ManifestSummary,
			signingPurpose: SigningPurpose
		) {
			self.reviewedTransaction = reviewedTransaction
			self.manifestSummary = manifestSummary
			self.signingPurpose = signingPurpose
			self.modeState = reviewedTransaction.transactionFee.customizationModeState
		}
	}

	enum ViewAction: Equatable, Sendable {
		case changeFeePayerTapped
		case toggleMode
		case closeButtonTapped
	}

	@CasePathable
	enum ChildAction: Equatable, Sendable {
		case normalFeesCustomization(NormalFeesCustomization.Action)
		case advancedFeesCustomization(AdvancedFeesCustomization.Action)
	}

	enum DelegateAction: Equatable, Sendable {
		case updated(ReviewedTransaction)
	}

	enum InternalAction: Equatable, Sendable {
		case updated(TaskResult<ReviewedTransaction>)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case selectFeePayer(SelectFeePayer.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case selectFeePayer(SelectFeePayer.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.selectFeePayer, action: \.selectFeePayer) {
				SelectFeePayer()
			}
		}
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Scope(state: \.modeState, action: \.child) {
			Scope(state: \.normal, action: \.normalFeesCustomization) {
				NormalFeesCustomization()
			}
			Scope(state: \.advanced, action: \.advancedFeesCustomization) {
				AdvancedFeesCustomization()
			}
		}
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .changeFeePayerTapped:
			state.destination = .selectFeePayer(
				.init(
					reviewedTransaction: state.reviewedTransaction,
					selectedFeePayer: state.feePayer,
					transactionFee: state.transactionFee
				)
			)
			return .none
		case .toggleMode:
			state.reviewedTransaction.transactionFee.toggleMode()
			state.modeState = state.reviewedTransaction.transactionFee.customizationModeState
			return .send(.delegate(.updated(state.reviewedTransaction)))
		case .closeButtonTapped:
			return .run { _ in
				await dismiss()
			}
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .advancedFeesCustomization(.delegate(.updated(advancedFees))):
			state.reviewedTransaction.transactionFee.mode = .advanced(advancedFees)
			return .send(.delegate(.updated(state.reviewedTransaction)))
		default:
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .updated(.success(reviewedTransaction)):
			state.reviewedTransaction = reviewedTransaction
			state.modeState = state.reviewedTransaction.transactionFee.customizationModeState
			return .send(.delegate(.updated(state.reviewedTransaction)))
		case let .updated(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .selectFeePayer(.delegate(.selected(selection))):
			let previousFeePayer = state.feePayer
			state.destination = nil
			let signingPurpose = state.signingPurpose

			@Sendable
			func replaceFeePayer(
				_ feePayer: FeePayerCandidate,
				_ reviewedTransaction: ReviewedTransaction,
				manifestSummary: ManifestSummary
			) -> Effect<Action> {
				.run { send in
					var reviewedTransaction = reviewedTransaction
					var newSigners = OrderedSet(reviewedTransaction.transactionSigners.intentSignerEntitiesOrEmpty())

					/// Remove the previous Fee Payer Signature if it is not required
					if let previousFeePayer, !manifestSummary.addressesOfAccountsRequiringAuth.contains(where: { $0 == previousFeePayer.account.address }) {
						// removed, need to recalculate signing factors
						newSigners.remove(.account(previousFeePayer.account))
					}

					newSigners.append(.account(feePayer.account))

					// Update transaction signers
					reviewedTransaction.transactionSigners = .init(
						notaryPublicKey: reviewedTransaction.transactionSigners.notaryPublicKey,
						intentSigning: {
							guard let nonEmpty = NonEmpty(rawValue: OrderedSet(newSigners)) else {
								return .notaryIsSignatory
							}
							return TransactionSigners.IntentSigning.intentSigners(nonEmpty)
						}()
					)

					@Dependency(\.factorSourcesClient) var factorSourcesClient

					do {
						guard let signers = NonEmpty(rawValue: Set(newSigners)) else {
							assertionFailure("NewSigners can not be empty here, barring programmer errors")
							struct InternalError: Error {}
							throw InternalError()
						}

						let factors = try await factorSourcesClient.getSigningFactors(.init(
							networkID: reviewedTransaction.networkID,
							signers: signers,
							signingPurpose: signingPurpose
						))

						reviewedTransaction.signingFactors = factors
						reviewedTransaction.feePayer = .success(selection)
						if previousFeePayer == nil, reviewedTransaction.transactionFee.totalFee.max == .zero {
							/// The case when no FeePayer is required, but users chooses to add a FeePayer.
							reviewedTransaction.transactionFee.addLockFeeCost()
							reviewedTransaction.transactionFee.updateNotarizingCost(notaryIsSignatory: false)
						}
						reviewedTransaction.transactionFee.updateSignaturesCost(factors.expectedSignatureCount)
						await send(.internal(.updated(.success(reviewedTransaction))))
					} catch {
						await send(.internal(.updated(.failure(error))))
					}
				}
			}

			if selection != previousFeePayer {
				return replaceFeePayer(selection, state.reviewedTransaction, manifestSummary: state.manifestSummary)
			} else {
				return .none
			}

		default:
			return .none
		}
	}
}

extension TransactionFee {
	var customizationModeState: CustomizeFees.State.CustomizationModeState {
		switch mode {
		case let .normal(normal):
			.normal(.init(fees: normal))
		case let .advanced(advanced):
			.advanced(.init(fees: advanced))
		}
	}
}
