import ComposableArchitecture
import SwiftUI

public struct DefaultDepositGuarantees: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: State

	public struct State: Sendable, Hashable {
		public var depositGuarantee: Decimal192? {
			percentageStepper.value.map { Decimal192(0.01) * $0 }
		}

		var percentageStepper: MinimumPercentageStepper.State

		public init(depositGuarantee: Decimal192) {
			self.percentageStepper = .init(value: Decimal192(100) * depositGuarantee)
		}
	}

	// MARK: Action

	public enum ChildAction: Sendable, Equatable {
		case percentageStepper(MinimumPercentageStepper.Action)
	}

	// MARK: Reducer

	public var body: some ReducerOf<Self> {
		Scope(state: \.percentageStepper, action: /Action.child .. /ChildAction.percentageStepper) {
			MinimumPercentageStepper()
		}
	}
}
