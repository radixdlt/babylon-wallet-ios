import ComposableArchitecture
import SwiftUI

// MARK: - LSUDetails
struct LSUDetails: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let validator: OnLedgerEntity.Validator
		let stakeUnitResource: OnLedgerEntitiesClient.ResourceWithVaultAmount
		let xrdRedemptionValue: ResourceAmount
	}

	@Dependency(\.dismiss) var dismiss

	enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
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
