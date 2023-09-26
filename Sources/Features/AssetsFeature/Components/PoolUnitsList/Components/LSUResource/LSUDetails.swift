import FeaturePrelude

// MARK: - LSUDetails
public struct LSUDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let validator: AccountPortfolio.PoolUnitResources.RadixNetworkStake.Validator
		let stakeUnitResource: OnLedgerEntity.Resource
		let stakeAmount: BigDecimal
		let xrdRedemptionValue: BigDecimal
	}

	@Dependency(\.dismiss) var dismiss

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .run { _ in
				await dismiss()
			}
		}
	}
}
