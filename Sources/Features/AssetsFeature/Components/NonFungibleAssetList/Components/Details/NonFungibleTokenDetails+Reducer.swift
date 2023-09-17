import FeaturePrelude

// MARK: - NonFungibleTokenDetails
public struct NonFungibleTokenDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let token: AccountPortfolio.NonFungibleResource.NonFungibleToken?
		public let resource: AccountPortfolio.NonFungibleResource

		public init(token: AccountPortfolio.NonFungibleResource.NonFungibleToken?, resource: AccountPortfolio.NonFungibleResource) {
			self.token = token
			self.resource = resource
		}
	}

//	public enum ViewAction: Sendable, Equatable {
//		case closeButtonTapped
//	}

//	public enum DelegateAction: Sendable, Equatable {
//		case dismiss
//	}

	public init() {}

//	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
//		switch viewAction {
//		case .closeButtonTapped:
//			return .send(.delegate(.dismiss))
//		}
//	}
}
