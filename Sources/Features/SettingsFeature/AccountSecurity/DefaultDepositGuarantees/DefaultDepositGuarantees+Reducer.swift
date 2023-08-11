import AppPreferencesClient
import FactorSourcesClient
import FeaturePrelude
import LedgerHardwareDevicesFeature
import TransactionReviewFeature

public struct DefaultDepositGuarantees: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: State

	public struct State: Sendable, Hashable {
		public var percentageStepper: MinimumPercentageStepper.State

		public init() {
			//			self.percentageStepper = .init(value: 100 * guaranteed / transfer.amount)
			self.percentageStepper = .init(value: 100)
		}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum InternalAction: Sendable, Equatable {}

	public enum ChildAction: Sendable, Equatable {
		case percentageStepper(MinimumPercentageStepper.Action)
	}

	// MARK: Reducer

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.percentageStepper, action: /Action.child .. /ChildAction.percentageStepper) {
			MinimumPercentageStepper()
		}
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}

//	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
//		switch internalAction {
//		}
//	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .percentageStepper(.delegate(.valueChanged)):
			guard let value = state.percentageStepper.value else {
//				state.transfer.guarantee?.amount = 0
				return .none
			}

			let newMinimumDecimal = value * 0.01
//			let newAmount = newMinimumDecimal * state.transfer.amount
//			state.transfer.guarantee?.amount = newAmount

			return .none

		case .percentageStepper:
			return .none
		}
	}
}
