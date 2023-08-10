import FeaturePrelude

public struct LSUDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public var id: String {
			stake.validator.address.address
		}

		let stake: AccountPortfolio.PoolUnitResources.RadixNetworkStake
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
