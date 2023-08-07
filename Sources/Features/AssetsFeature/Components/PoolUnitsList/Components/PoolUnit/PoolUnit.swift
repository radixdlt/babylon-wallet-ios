import FeaturePrelude

// MARK: - PoolUnit
public struct PoolUnit: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		// Int temp
		public let id: Int

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
			case details(Prelude.Unit)
		}

		public enum Action: Sendable, Equatable {
			case details(FungibleTokenDetails.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.details, action: /Action.details) {
				EmptyReducer()
			}
		}
	}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(
				\.$destination,
				action: /Action.child .. ChildAction.destination
			) {
				Destinations()
			}
	}

	public func reduce(
		into state: inout State,
		viewAction: ViewAction
	) -> EffectTask<Action> {
		switch viewAction {
		case .didTap:
			state.destination = .details(.instance)

			return .none
		}
	}
}
