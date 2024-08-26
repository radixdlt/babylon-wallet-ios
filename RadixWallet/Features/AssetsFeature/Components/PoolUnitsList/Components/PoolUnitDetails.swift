import ComposableArchitecture
import SwiftUI

// MARK: - PoolUnitDetails
public struct PoolUnitDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let resourcesDetails: OnLedgerEntitiesClient.OwnedResourcePoolDetails
		var hideResource: HideResource.State

		public init(resourcesDetails: OnLedgerEntitiesClient.OwnedResourcePoolDetails) {
			self.resourcesDetails = resourcesDetails
			self.hideResource = .init(kind: .poolUnit(resourcesDetails.address))
		}
	}

	@Dependency(\.dismiss) var dismiss

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case hideResource(HideResource.Action)
	}

	public var body: some ReducerOf<Self> {
		Scope(state: \.hideResource, action: \.child.hideResource) {
			HideResource()
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			.run { _ in
				await dismiss()
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .hideResource(.delegate(.didHideResource)):
			.run { _ in await dismiss() }
		default:
			.none
		}
	}
}
