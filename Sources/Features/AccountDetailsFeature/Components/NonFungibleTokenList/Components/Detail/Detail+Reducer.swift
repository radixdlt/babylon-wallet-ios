import FeaturePrelude

// MARK: - NonFungibleTokenList.Detail
extension NonFungibleTokenList {
	// MARK: - NonFungibleTokenDetails
	public struct Detail: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable {
			let resource: AccountPortfolio.NonFungibleResource
			let localId: AccountPortfolio.NonFungibleResource.NonFungibleToken.LocalID
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
}
