import FeaturePrelude

extension FungibleTokenList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
                        public var id: FungibleToken.ID { token.id }

			public var token: FungibleToken

			public init(
                                token: FungibleToken
			) {
				self.token = token
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case tapped
		}

		public enum DelegateAction: Sendable, Equatable {
			case selected(FungibleToken)
		}

		public init() {}

		public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
			switch viewAction {
			case .tapped:
                                return .send(.delegate(.selected(state.token)))
			}
		}
	}
}
