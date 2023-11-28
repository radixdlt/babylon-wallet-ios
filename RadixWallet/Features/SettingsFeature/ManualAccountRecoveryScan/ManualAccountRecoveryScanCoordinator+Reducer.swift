import ComposableArchitecture
import SwiftUI

// MARK: - ManualAccountRecoveryScanCoordinator
public struct ManualAccountRecoveryScanCoordinator: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public struct State: Sendable, Hashable {
		public var path: StackState<Path.State>
	}

	public struct Path: Sendable, Hashable, Reducer {
		public enum State: Sendable, Hashable {
			case chooseSeedPhrase(ChooseSeedPhrase.State)
			case chooseLedger(ChooseLedger.State)
		}

		public enum Action: Sendable, Equatable {
			case chooseSeedPhrase(ChooseSeedPhrase.Action)
			case chooseLedger(ChooseLedger.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.chooseLedger, action: /Action.chooseLedger) {
				ChooseLedger()
			}
			Scope(state: /State.chooseSeedPhrase, action: /Action.chooseSeedPhrase) {
				ChooseSeedPhrase()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum ChildAction: Sendable, Equatable {
		case path(StackActionOf<Path>)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .path(.element(id: id, action: pathAction)):
			reduce(into: &state, id: id, pathAction: pathAction)
		case let .path(.popFrom(id: id)):
			.none
		case let .path(.push(id: id, state: pathState)):
			.none
		}
	}

	public func reduce(into state: inout State, id: StackElementID, pathAction: Path.Action) -> Effect<Action> {
//		switch pathAction {
//		}
		.none
	}
}

extension ManualAccountRecoveryScanCoordinator {
	public struct ChooseLedger: Sendable, FeatureReducer {
		public typealias Store = StoreOf<Self>

		public struct State: Sendable, Hashable {}
	}

	public struct ChooseSeedPhrase: Sendable, FeatureReducer {
		public typealias Store = StoreOf<Self>

		public struct State: Sendable, Hashable {}
	}
}
