import ComposableArchitecture
import SwiftUI

// MARK: - PoolUnitsList
public struct PoolUnitsList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var poolUnits: IdentifiedArrayOf<PoolUnitState>

		public struct PoolUnitState: Sendable, Hashable, Identifiable {
			public var id: PoolAddress { poolUnit.resourcePoolAddress }
			public var poolUnit: OnLedgerEntity.OnLedgerAccount.PoolUnit
			public var resourceDetails: Loadable<OnLedgerEntitiesClient.OwnedResourcePoolDetails> = .idle
			public var isSelected: Bool? = nil
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case poolUnitWasTapped(PoolAddress)
	}

	public enum DelegateAction: Sendable, Equatable {
		case selected(OnLedgerEntitiesClient.OwnedResourcePoolDetails)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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
