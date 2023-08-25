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

		var feePayerSelection: FeePayerSelectionAmongstCandidates
		var transactionSigners: TransactionSigners
		let networkID: NetworkID
		let signingPurpose: SigningPurpose

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
			feePayerSelection: FeePayerSelectionAmongstCandidates,
			transactionSigners: TransactionSigners,
			networkID: NetworkID,
			signingPurpose: SigningPurpose
		) {
			self.feePayerSelection = feePayerSelection
			self.transactionSigners = transactionSigners
			self.networkID = networkID
			self.signingPurpose = signingPurpose

			self.modeState = feePayerSelection.transactionFee.customizationModeState
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
		case updated(FeePayerSelectionAmongstCandidates)
	}

	public enum InternalAction: Equatable, Sendable {
		case updated(FeePayerSelectionAmongstCandidates)
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
			state.feePayerSelection.transactionFee.toggleMode()
			state.modeState = state.feePayerSelection.transactionFee.customizationModeState
			return .send(.delegate(.updated(state.feePayerSelection)))
		case .closeButtonTapped:
			return .run { _ in
				await dismiss()
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.selectFeePayer(.delegate(.selected(selection))))):
			state.feePayerSelection.selected = selection
			state.destination = nil
			let feePayer = EntityPotentiallyVirtual.account(selection.account)

			return .run { [transactionSigners = state.transactionSigners, feePayerSelection = state.feePayerSelection, networkID = state.networkID, signingPurpose = state.signingPurpose] send in
				@Dependency(\.factorSourcesClient) var factorSourcesClient

				// Note: Here we do just determine the new signatures count.
				//       The Fee Payer signature will be added if needed when approving the transaction.
				let newSigners = transactionSigners.intentSignerEntitiesOrEmpty() + [feePayer]
				let factors = try await factorSourcesClient.getSigningFactors(.init(
					networkID: networkID,
					signers: .init(rawValue: Set(newSigners))!,
					signingPurpose: signingPurpose
				))

				var feePayerSelection = feePayerSelection
				feePayerSelection.transactionFee.updatingSignaturesCost(factors.expectedSignatureCount)

				await send(.internal(.updated(feePayerSelection)))
			}
		case let .advancedFeesCustomization(.delegate(.updated(advancedFees))):
			state.feePayerSelection.transactionFee.mode = .advanced(advancedFees)
			return .send(.delegate(.updated(state.feePayerSelection)))
		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .updated(feePayerSelection):
			state.feePayerSelection = feePayerSelection
			state.modeState = state.feePayerSelection.transactionFee.customizationModeState
			return .send(.delegate(.updated(feePayerSelection)))
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
