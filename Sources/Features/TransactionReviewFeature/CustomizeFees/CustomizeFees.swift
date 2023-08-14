import EngineKit
import FeaturePrelude
import TransactionClient

// MARK: - CustomizeFees
public struct CustomizeFees: FeatureReducer {
	public struct State: Hashable, Sendable {
		enum CustomizationModeState: Hashable, Sendable {
			case normal(NormalCustomizationFees.State)
			case advanced(AdvancedCustomizationFees.State)
		}

		var feePayerSelection: FeePayerSelectionAmongstCandidates

		var feePayerAccount: Profile.Network.Account? {
			feePayerSelection.selected?.account
		}

		var transactionFee: TransactionFee {
			feePayerSelection.transactionFee
		}

		@PresentationState
		public var destination: Destinations.State? = nil

		var modeState: CustomizationModeState

		init(
			feePayerSelection: FeePayerSelectionAmongstCandidates
		) {
			self.feePayerSelection = feePayerSelection
			self.modeState = feePayerSelection.transactionFee.customizationModeState
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case changeFeePayerTapped
		case toggleMode
		case closed
	}

	public enum ChildAction: Equatable, Sendable {
		case destination(PresentationAction<Destinations.Action>)
		case normalFeeCustomization(NormalCustomizationFees.Action)
		case advancedFeeCustomization(AdvancedCustomizationFees.Action)
	}

	public enum DelegateAction: Equatable, Sendable {
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
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}

		Scope(state: \.modeState, action: /Action.child) {
			EmptyReducer()
				.ifCaseLet(/State.CustomizationModeState.normal, action: /ChildAction.normalFeeCustomization) {
					NormalCustomizationFees()
				}
				.ifCaseLet(/State.CustomizationModeState.advanced, action: /ChildAction.advancedFeeCustomization) {
					AdvancedCustomizationFees()
				}
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
		case .closed:
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
			return .send(.delegate(.updated(state.feePayerSelection)))

		default:
			return .none
		}
	}
}

extension TransactionFee {
	var customizationModeState: CustomizeFees.State.CustomizationModeState {
		switch mode {
		case let .normal(normal):
			return .normal(.init(normalCustomization: normal))
		case let .advanced(advanced):
			return .advanced(.init(advancedCustomization: advanced))
		}
	}
}
