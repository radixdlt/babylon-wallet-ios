import ComposableArchitecture
import SwiftUI

// MARK: - FungibleAssetList
public struct FungibleAssetList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var sections: IdentifiedArrayOf<FungibleAssetList.Section.State> = []

		public mutating func update(
			token: OnLedgerEntity.OwnedFungibleResource,
			for sectionID: Section.State.ID
		) -> FungibleAssetList.Section.Row.State? {
			guard
				let xrdSection = sections.first(where: { $0.id == sectionID }),
				var row = xrdSection.rows.first(where: { $0.id == token.resourceAddress })
			else { return nil }

			row.token = token

			return row
		}
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case section(FungibleAssetList.Section.State.ID, FungibleAssetList.Section.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case selected(OnLedgerEntity.OwnedFungibleResource, isXrd: Bool)
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.sections, action: /Action.child .. ChildAction.section) {
				FungibleAssetList.Section()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .section(id, .delegate(.selected(resource))):
			.send(.delegate(.selected(resource, isXrd: id == .xrd)))
		case .section:
			.none
		}
	}
}
