import ComposableArchitecture
import SwiftUI

// MARK: - LSUDetails
@Reducer
struct LSUDetails: FeatureReducer {
	@ObservableState
	struct State: Hashable {
		let validator: OnLedgerEntity.Validator
		let stakeUnitResource: OnLedgerEntitiesClient.ResourceWithVaultAmount
		let xrdRedemptionValue: ResourceAmount
	}

	@Dependency(\.dismiss) var dismiss

	typealias Action = FeatureAction<Self>

	enum ViewAction: Equatable {
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
