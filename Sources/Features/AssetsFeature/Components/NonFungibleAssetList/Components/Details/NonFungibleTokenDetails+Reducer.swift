import FeaturePrelude

// MARK: - NonFungibleTokenDetails
public struct NonFungibleTokenDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let resource: OnLedgerEntity.Resource
		public let token: AccountPortfolio.NonFungibleResource.NonFungibleToken?

		public init(resource: OnLedgerEntity.Resource, token: AccountPortfolio.NonFungibleResource.NonFungibleToken? = nil) {
			self.resource = resource
			self.token = token
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .send(.delegate(.dismiss))
		}
	}
}
