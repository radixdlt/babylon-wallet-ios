import ComposableArchitecture
import SwiftUI

// MARK: - LSUDetails
public struct LSUDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let validator: OnLedgerEntity.Validator
		let stakeUnitResource: OnLedgerEntitiesClient.ResourceWithVaultAmount
		let xrdRedemptionValue: RETDecimal
	}

	@Dependency(\.dismiss) var dismiss

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			.run { _ in
				await dismiss()
			}
		}
	}
}
