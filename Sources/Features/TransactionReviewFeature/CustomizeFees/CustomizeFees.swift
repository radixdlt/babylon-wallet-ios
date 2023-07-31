import EngineKit
import FeaturePrelude
import TransactionClient

struct CustomizeFees: FeatureReducer {
	struct State: Hashable, Sendable {
		var feePayerCandidates: FeePayerSelectionAmongstCandidates
		let feeSummary: FeeSummary
		let feeLocks: FeeLocks
		var tip: BigDecimal
		var feePayerAccount: Profile.Network.Account {
			feePayerCandidates.selected.account
		}

		@PresentationState
		public var destination: Destinations.State? = nil

		var total: BigDecimal {
			tip
		}

		init(
			feePayerCandidates: FeePayerSelectionAmongstCandidates,
			feeSummary: FeeSummary,
			feeLocks: FeeLocks,
			tip: BigDecimal,
			total: BigDecimal
		) {
			self.feePayerCandidates = feePayerCandidates
			self.feeSummary = feeSummary
			self.feeLocks = feeLocks
			self.tip = .zero
		}
	}

	enum ViewAction: Equatable {
		case changeFeePayerTapped
		case viewAdvancedModeTapped
	}

	enum ChildAction: Equatable {
		case destination(PresentationAction<Destinations.Action>)
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

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .changeFeePayerTapped:
			state.destination = .selectFeePayer(.init(candidates: state.feePayerCandidates.candidates, fee: state.feePayerCandidates.fee))
			return .none
		case .viewAdvancedModeTapped:
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.selectFeePayer(.delegate(.selected(selection))))):
			state.feePayerCandidates = selection
			return .none
		default:
			return .none
		}
	}
}
