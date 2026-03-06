import ComposableArchitecture
import SwiftUI

struct DefaultDepositGuarantees: FeatureReducer {
	typealias Store = StoreOf<Self>

	init() {}

	// MARK: State

	struct State: Hashable {
		var depositGuarantee: Decimal192? {
			percentageStepper.value.map { try! Decimal192(0.01) * $0 }
		}

		var percentageStepper: MinimumPercentageStepper.State

		init(depositGuarantee: Decimal192) {
			self.percentageStepper = .init(value: 100 * depositGuarantee)
		}
	}

	// MARK: Action

	enum ChildAction: Equatable {
		case percentageStepper(MinimumPercentageStepper.Action)
	}

	// MARK: Reducer

	var body: some ReducerOf<Self> {
		Scope(state: \.percentageStepper, action: /Action.child .. /ChildAction.percentageStepper) {
			MinimumPercentageStepper()
		}
	}
}
