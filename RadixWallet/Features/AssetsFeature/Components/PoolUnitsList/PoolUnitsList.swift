import ComposableArchitecture
import SwiftUI

// MARK: - PoolUnitsList
struct PoolUnitsList: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var poolUnits: IdentifiedArrayOf<PoolUnitState>

		struct PoolUnitState: Sendable, Hashable, Identifiable {
			var id: PoolAddress { poolUnit.resourcePoolAddress }
			var poolUnit: OnLedgerEntity.OnLedgerAccount.PoolUnit
			var resourceDetails: Loadable<OnLedgerEntitiesClient.OwnedResourcePoolDetails> = .idle
			var isSelected: Bool? = nil
		}
	}

	enum ViewAction: Sendable, Equatable {
		case poolUnitWasTapped(PoolAddress)
	}

	enum DelegateAction: Sendable, Equatable {
		case selected(OnLedgerEntitiesClient.OwnedResourcePoolDetails)
	}

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .poolUnitWasTapped(id):
			if let isSelected = state.poolUnits[id: id]?.isSelected {
				state.poolUnits[id: id]?.isSelected = !isSelected
				return .none
			} else {
				guard let poolUnit = state.poolUnits[id: id], case let .success(details) = poolUnit.resourceDetails else {
					return .none
				}

				return .send(.delegate(.selected(details)))
			}
		}
	}
}
