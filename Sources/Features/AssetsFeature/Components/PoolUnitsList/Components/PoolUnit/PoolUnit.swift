import EngineKit
import FeaturePrelude

// MARK: - PoolUnit
public struct PoolUnit: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public var id: ResourcePoolAddress {
			poolUnit.poolAddress
		}

		let poolUnit: AccountPortfolio.PoolUnitResources.PoolUnit

		var isSelected: Bool?

		@PresentationState
		var destination: Destinations.State?
	}

	public enum ViewAction: Sendable, Equatable {
		case didTap
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case details(PoolUnitDetails.State)
		}

		public enum Action: Sendable, Equatable {
			case details(PoolUnitDetails.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(
				state: /State.details,
				action: /Action.details,
				child: PoolUnitDetails.init
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
			if state.isSelected != nil {
				state.isSelected?.toggle()
			} else {
				state.destination = .details(
					.init(poolUnit: state.poolUnit)
				)
			}

			return .none
		}
	}
}
