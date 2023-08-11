import FeaturePrelude

// MARK: - LSUDetails
public struct LSUDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let validator: AccountPortfolio.PoolUnitResources.RadixNetworkStake.Validator
		let stakeUnitResource: AccountPortfolio.FungibleResource
	}

	@Dependency(\.dismiss) var dismiss

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .run { _ in
				await dismiss()
			}
		}
	}
}

extension AccountPortfolio {
	static func xrdRedemptionValue(
		validator: AccountPortfolio.PoolUnitResources.RadixNetworkStake.Validator,
		stakeUnitResource: AccountPortfolio.FungibleResource
	) -> BigDecimal {
		(stakeUnitResource.amount * validator.xrdVaultBalance) / (stakeUnitResource.totalSupply ?? .one)
	}
}
