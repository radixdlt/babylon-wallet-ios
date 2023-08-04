import EngineKit
import FeaturePrelude
import TransactionClient

public struct CustomizeFees: FeatureReducer {
	public struct State: Hashable, Sendable {
		var feePayerSelection: FeePayerSelectionAmongstCandidates

		var feePayerAccount: Profile.Network.Account? {
			feePayerSelection.selected?.account
		}

		var transactionFee: TransactionFee {
			feePayerSelection.transactionFee
		}

		@PresentationState
		public var destination: Destinations.State? = nil

		init(
			feePayerSelection: FeePayerSelectionAmongstCandidates
		) {
			self.feePayerSelection = feePayerSelection
		}
	}

	public enum ViewAction: Equatable {
		case changeFeePayerTapped
		case toggleMode
		case totalNetworkAndRoyaltyFeesChanged(String)
		case tipPercentageChanged(String)
		case closed
	}

	public enum ChildAction: Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Equatable {
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
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .changeFeePayerTapped:
			state.destination = .selectFeePayer(.init(feePayerSelection: state.feePayerSelection))
			return .none
		case .toggleMode:
			state.feePayerSelection.transactionFee.toggleMode()
			return .send(.delegate(.updated(state.feePayerSelection)))
		case let .totalNetworkAndRoyaltyFeesChanged(amount):
			guard case let .advanced(advanced) = state.transactionFee.mode, let value = try? BigDecimal(localizedFromString: amount) else {
				return .none
			}

			state.feePayerSelection.transactionFee.mode = .advanced(.init(networkAndRoyaltyFee: value, tipPercentage: advanced.tipPercentage))
			return .send(.delegate(.updated(state.feePayerSelection)))
		case let .tipPercentageChanged(percentage):
			guard case let .advanced(advanced) = state.transactionFee.mode, let value = try? BigDecimal(localizedFromString: percentage) else {
				return .none
			}

			state.feePayerSelection.transactionFee.mode = .advanced(.init(networkAndRoyaltyFee: advanced.networkAndRoyaltyFee, tipPercentage: value))
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
