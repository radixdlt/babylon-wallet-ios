import ComposableArchitecture
import SwiftUI

// MARK: - PoolUnitsList
public struct PoolUnitsList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var poolUnits: IdentifiedArrayOf<PoolUnit.State>
	}

	public enum ChildAction: Sendable, Equatable {
		case poolUnit(id: PoolUnit.State.ID, action: PoolUnit.Action)
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.poolUnits, action: /Action.child .. ChildAction.poolUnit) {
				PoolUnit()
			}
	}
}
