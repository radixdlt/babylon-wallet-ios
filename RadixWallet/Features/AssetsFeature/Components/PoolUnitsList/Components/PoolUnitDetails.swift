import ComposableArchitecture
import SwiftUI

// MARK: - PoolUnitDetails
public struct PoolUnitDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let resourcesDetails: OnLedgerEntitiesClient.OwnedResourcePoolDetails
		var hideAsset: HideAsset.State

		public init(resourcesDetails: OnLedgerEntitiesClient.OwnedResourcePoolDetails) {
			self.resourcesDetails = resourcesDetails
			self.hideAsset = .init(asset: .poolUnit(resourcesDetails.address))
		}
	}

	@Dependency(\.dismiss) var dismiss

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case hideAsset(HideAsset.Action)
	}

	public var body: some ReducerOf<Self> {
		Scope(state: \.hideAsset, action: \.child.hideAsset) {
			HideAsset()
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
		case .hideAsset(.delegate(.didHideAsset)):
			.run { _ in await dismiss() }
		default:
			.none
		}
	}
}
