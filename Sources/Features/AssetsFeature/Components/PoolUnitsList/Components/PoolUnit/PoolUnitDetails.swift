import FeaturePrelude

// MARK: - PoolUnitDetails
public struct PoolUnitDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let poolUnit: AccountPortfolio.PoolUnitResources.PoolUnit
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
