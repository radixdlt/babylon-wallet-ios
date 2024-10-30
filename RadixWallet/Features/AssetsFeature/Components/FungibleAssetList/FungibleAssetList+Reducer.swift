import ComposableArchitecture
import SwiftUI

// MARK: - FungibleAssetList
struct FungibleAssetList: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var sections: IdentifiedArrayOf<FungibleAssetList.Section.State> = []
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case section(FungibleAssetList.Section.State.ID, FungibleAssetList.Section.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case selected(OnLedgerEntity.OwnedFungibleResource, isXrd: Bool)
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.sections, action: /Action.child .. ChildAction.section) {
				FungibleAssetList.Section()
			}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .section(id, .delegate(.selected(resource))):
			.send(.delegate(.selected(resource, isXrd: id == .xrd)))
		case .section:
			.none
		}
	}
}
