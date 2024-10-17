import ComposableArchitecture
import SwiftUI

struct DefaultDepositGuarantees: Sendable, FeatureReducer {
	typealias Store = StoreOf<Self>

	init() {}

	// MARK: State

	struct State: Sendable, Hashable {
		var depositGuarantee: Decimal192? {
			percentageStepper.value.map { try! Decimal192(0.01) * $0 }
		}

		var percentageStepper: MinimumPercentageStepper.State

		init(depositGuarantee: Decimal192) {
			self.percentageStepper = .init(value: 100 * depositGuarantee)
		}
	}

	// MARK: Action

	enum ChildAction: Sendable, Equatable {
		case percentageStepper(MinimumPercentageStepper.Action)
	}

	// MARK: Reducer

	var body: some ReducerOf<Self> {
		Scope(state: \.percentageStepper, action: /Action.child .. /ChildAction.percentageStepper) {
			MinimumPercentageStepper()
		}
	}
}
