import FeaturePrelude

extension FungibleTokenList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
                        public var id: ResourceAddress { token.resourceAddress}

                        public var token: AccountPortfolio.FungibleToken
                        public var isXRD: Bool

			public init(
                                token: AccountPortfolio.FungibleToken,
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
                        case selected(AccountPortfolio.FungibleToken)
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
