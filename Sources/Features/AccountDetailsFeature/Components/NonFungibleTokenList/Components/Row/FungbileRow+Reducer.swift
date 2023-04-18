import FeaturePrelude

extension NonFungibleTokenList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			public var id: ResourceAddress { token.resourceAddress }

			public var token: AccountPortfolio.NonFungibleResource
			public var isExpanded = false

			public init(
				token: AccountPortfolio.NonFungibleResource
			) {
				self.token = token
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case isExpandedToggled
			// case selected(NonFungibleTokenList.Detail.State)
		}

		public enum DelegateAction: Sendable, Equatable {
			// case selected(NonFungibleTokenList.Detail.State)
		}

		public init() {}

		public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
			switch viewAction {
//			case let .selected(token):
//				return .send(.delegate(.selected(token)))

			case .isExpandedToggled:
				state.isExpanded.toggle()
				return .none
			}
		}
	}
}
