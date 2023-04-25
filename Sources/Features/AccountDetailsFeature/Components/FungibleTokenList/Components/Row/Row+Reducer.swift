import FeaturePrelude

extension FungibleTokenList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			public typealias ID = ResourceAddress
			public var id: ID { token.resourceAddress }

			public var token: AccountPortfolio.FungibleResource
			public var isXRD: Bool

			public init(xrdToken: AccountPortfolio.FungibleResource) {
				self.init(token: xrdToken, isXRD: true)
			}

			public init(nonXRDToken: AccountPortfolio.FungibleResource) {
				self.init(token: nonXRDToken, isXRD: false)
			}

			init(
				token: AccountPortfolio.FungibleResource,
				isXRD: Bool
			) {
				self.token = token
				self.isXRD = isXRD
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case tapped
		}

		public enum DelegateAction: Sendable, Equatable {
			case selected(AccountPortfolio.FungibleResource)
		}

		public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
			switch viewAction {
			case .tapped:
				return .send(.delegate(.selected(state.token)))
			}
		}
	}
}
