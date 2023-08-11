import FeaturePrelude

public struct LSUComponent: FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public var id: String {
			"\(stake)"
		}

		let stake: Int

		@PresentationState
		public var destination: Destinations.State?
	}

	public enum ViewAction: Sendable, Equatable {
		case didTap
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case details(LSUDetails.State)
		}

		public enum Action: Sendable, Equatable {
			case details(LSUDetails.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(
				state: /State.details,
				action: /Action.details,
				child: LSUDetails.init
			)
		}
	}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(
				\.$destination,
				action: /Action.child .. ChildAction.destination,
				destination: Destinations.init
			)
	}

	public func reduce(
		into state: inout State,
		viewAction: ViewAction
	) -> EffectTask<Action> {
		switch viewAction {
		case .didTap:
			state.destination = .details(.init(stake: 3))

			return .none
		}
	}
}
