import FeaturePrelude

extension NonFungibleTokenList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			public var id: ResourceAddress { resource.resourceAddress }

			public let resource: AccountPortfolio.NonFungibleResource
			public var isExpanded = false

			public init(
				resource: AccountPortfolio.NonFungibleResource
			) {
				self.resource = resource
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case isExpandedToggled
			case tokenTapped(AccountPortfolio.NonFungibleResource.NonFungibleToken.LocalID)
		}

		public enum DelegateAction: Sendable, Equatable {
			case open(AccountPortfolio.NonFungibleResource.NonFungibleToken.LocalID)
		}

		public init() {}

		public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
			switch viewAction {
			case let .tokenTapped(localID):
				return .send(.delegate(.open(localID)))

			case .isExpandedToggled:
				state.isExpanded.toggle()
				return .none
			}
		}
	}
}
