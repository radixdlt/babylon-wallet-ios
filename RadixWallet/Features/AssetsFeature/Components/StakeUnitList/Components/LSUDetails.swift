import ComposableArchitecture
import SwiftUI

// MARK: - LSUDetails
@Reducer
struct LSUDetails: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let validator: OnLedgerEntity.Validator
		let stakeUnitResource: OnLedgerEntitiesClient.ResourceWithVaultAmount
		let xrdRedemptionValue: ResourceAmount
	}

	@Dependency(\.dismiss) var dismiss

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	var body: some ReducerOf<Self> {
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
}
