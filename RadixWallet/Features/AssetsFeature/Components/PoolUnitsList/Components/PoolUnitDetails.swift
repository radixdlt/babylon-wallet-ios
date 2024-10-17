import ComposableArchitecture
import SwiftUI

// MARK: - PoolUnitDetails
struct PoolUnitDetails: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let resourcesDetails: OnLedgerEntitiesClient.OwnedResourcePoolDetails
		var hideResource: HideResource.State

		init(resourcesDetails: OnLedgerEntitiesClient.OwnedResourcePoolDetails) {
			self.resourcesDetails = resourcesDetails
			self.hideResource = .init(kind: .poolUnit(resourcesDetails.address))
		}
	}

	@Dependency(\.dismiss) var dismiss

	enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case hideResource(HideResource.Action)
	}

	var body: some ReducerOf<Self> {
		Scope(state: \.hideResource, action: \.child.hideResource) {
			HideResource()
		}

		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			.run { _ in
				await dismiss()
			}
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .hideResource(.delegate(.didHideResource)):
			.run { _ in await dismiss() }
		default:
			.none
		}
	}
}
