import EngineKit
import FactorSourcesClient
import FeaturePrelude
import TransactionClient

// MARK: - CustomizeFees
public struct CustomizeFees: FeatureReducer {
	public struct State: Hashable, Sendable {
		enum CustomizationModeState: Hashable, Sendable {
			case normal(NormalFeesCustomization.State)
			case advanced(AdvancedFeesCustomization.State)
		}

		var feePayerSelection: FeePayerSelectionAmongstCandidates {
			reviewedTransaction.feePayerSelectionAmongstCandidates
		}

		var reviewedTransaction: TransactionToReview
		var modeState: CustomizationModeState

		var feePayerAccount: Profile.Network.Account? {
			feePayerSelection.selected?.account
		}

		var transactionFee: TransactionFee {
			feePayerSelection.transactionFee
		}

		@PresentationState
		public var destination: Destinations.State? = nil

		init(
			reviewedTransaction: TransactionToReview
		) {
			self.reviewedTransaction = reviewedTransaction
			self.modeState = reviewedTransaction.feePayerSelectionAmongstCandidates.transactionFee.customizationModeState
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case changeFeePayerTapped
		case toggleMode
		case closeButtonTapped
	}

	public enum ChildAction: Equatable, Sendable {
		case destination(PresentationAction<Destinations.Action>)
		case normalFeesCustomization(NormalFeesCustomization.Action)
		case advancedFeesCustomization(AdvancedFeesCustomization.Action)
	}

	public enum DelegateAction: Equatable, Sendable {
		case updated(TransactionToReview)
	}

	public enum InternalAction: Equatable, Sendable {
		case factorsAndSignersUpdateResult(TaskResult<TransactionToReview>)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case selectFeePayer(SelectFeePayer.State)
		}

		public enum Action: Sendable, Equatable {
			case selectFeePayer(SelectFeePayer.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.selectFeePayer, action: /Action.selectFeePayer) {
				SelectFeePayer()
			}
		}
	}

	@Dependency(\.dismiss) var dismiss

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.modeState, action: /Action.child) {
			EmptyReducer()
				.ifCaseLet(/State.CustomizationModeState.normal, action: /ChildAction.normalFeesCustomization) {
					NormalFeesCustomization()
				}
				.ifCaseLet(/State.CustomizationModeState.advanced, action: /ChildAction.advancedFeesCustomization) {
					AdvancedFeesCustomization()
				}
		}

		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .changeFeePayerTapped:
			state.destination = .selectFeePayer(.init(feePayerSelection: state.feePayerSelection))
			return .none
		case .toggleMode:
			state.reviewedTransaction.feePayerSelectionAmongstCandidates.transactionFee.toggleMode()
			state.modeState = state.feePayerSelection.transactionFee.customizationModeState
			return .send(.delegate(.updated(state.reviewedTransaction)))
		case .closeButtonTapped:
			return .run { _ in
				await dismiss()
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.selectFeePayer(.delegate(.selected(selection))))):
			state.reviewedTransaction.feePayerSelectionAmongstCandidates.selected = selection
			state.destination = nil

			return .run { [reviewedTransaction = state.reviewedTransaction, feePayer = EntityPotentiallyVirtual.account(selection.account)] send in
				@Dependency(\.factorSourcesClient) var factorSourcesClient

				if !reviewedTransaction.transactionSigners.intentSignerEntitiesOrEmpty().contains(feePayer) {
					let newSigners = reviewedTransaction.transactionSigners.intentSignerEntitiesOrEmpty() + [feePayer]
					let nonEmptySigners = NonEmpty(rawValue: OrderedSet(newSigners))!
					// What to do on Failure? rever the fee payer?
					let factors = try await factorSourcesClient.getSigningFactors(.init(
						networkID: reviewedTransaction.networkID,
						signers: .init(rawValue: Set(newSigners))!,
						signingPurpose: .signTransaction(.manifestFromDapp)
					))
					var reviewedTransaction = reviewedTransaction
					reviewedTransaction.transactionSigners = .init(
						notaryPublicKey: reviewedTransaction.transactionSigners.notaryPublicKey,
						intentSigning: .intentSigners(.init(rawValue: OrderedSet(newSigners))!)
					)
					reviewedTransaction.signingFactors = factors
					reviewedTransaction.feePayerSelectionAmongstCandidates.transactionFee.updatingSignaturesCost(factors.expectedSignatureCount)

					await send(.internal(.factorsAndSignersUpdateResult(.success(reviewedTransaction))))
				}
				await send(.delegate(.updated(reviewedTransaction)))
			}
		case let .advancedFeesCustomization(.delegate(.updated(advancedFees))):
			state.reviewedTransaction.feePayerSelectionAmongstCandidates.transactionFee.mode = .advanced(advancedFees)
			return .send(.delegate(.updated(state.reviewedTransaction)))
		default:
			return .none
		}
	}
}

extension TransactionFee {
	var customizationModeState: CustomizeFees.State.CustomizationModeState {
		switch mode {
		case let .normal(normal):
			return .normal(.init(fees: normal))
		case let .advanced(advanced):
			return .advanced(.init(fees: advanced))
		}
	}
}
