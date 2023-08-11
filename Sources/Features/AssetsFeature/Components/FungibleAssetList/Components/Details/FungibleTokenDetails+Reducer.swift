import FeaturePrelude

// MARK: - FungibleTokenDetails
public struct FungibleTokenDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let resource: AccountPortfolio.FungibleResource
		let isXRD: Bool
		let behaviors: [AssetBehavior]

		public init(resource: AccountPortfolio.FungibleResource, isXRD: Bool, behaviors: [AssetBehavior]) {
			self.resource = resource
			self.isXRD = isXRD
			self.behaviors = behaviors
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .send(.delegate(.dismiss))
		}
	}
}
