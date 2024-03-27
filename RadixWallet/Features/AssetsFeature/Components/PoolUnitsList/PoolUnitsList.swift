import ComposableArchitecture
import SwiftUI

// MARK: - PoolUnitsList
public struct PoolUnitsList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var poolUnits: IdentifiedArrayOf<PoolUnitState>

		@PresentationState
		var destination: Destination.State?

		public struct PoolUnitState: Sendable, Hashable, Identifiable {
			public var id: PoolAddress { poolUnit.resourcePoolAddress }
			public let poolUnit: OnLedgerEntity.Account.PoolUnit
			public var resourceDetails: Loadable<OnLedgerEntitiesClient.OwnedResourcePoolDetails> = .idle
			public var isSelected: Bool? = nil
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case poolUnitWasTapped(PoolAddress)
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case details(PoolUnitDetails.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case details(PoolUnitDetails.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.details, action: /Action.details) {
				PoolUnitDetails()
			}
		}
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .poolUnitWasTapped(id):
			if let isSelected = state.poolUnits[id: id]?.isSelected {
				state.poolUnits[id: id]?.isSelected = !isSelected
			} else {
				guard let poolUnit = state.poolUnits[id: id], case let .success(details) = poolUnit.resourceDetails else {
					return .none
				}
				state.destination = .details(.init(resourcesDetails: details))
			}

			return .none
		}
	}
}
