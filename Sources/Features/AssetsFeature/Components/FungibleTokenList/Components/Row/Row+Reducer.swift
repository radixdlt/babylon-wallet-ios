import FeaturePrelude

extension FungibleTokenList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			public typealias ID = ResourceAddress
			public var id: ID { token.resourceAddress }

			public var token: AccountPortfolio.FungibleResource
			public var isXRD: Bool
			public var mode: Mode

			public enum Mode: Hashable, Sendable {
				case normal
				case selection(isSelected: Bool)
			}

			public init(xrdToken: AccountPortfolio.FungibleResource, mode: Mode = .normal) {
				self.init(token: xrdToken, isXRD: true, mode: mode)
			}

			public init(nonXRDToken: AccountPortfolio.FungibleResource, mode: Mode = .normal) {
				self.init(token: nonXRDToken, isXRD: false, mode: mode)
			}

			init(
				token: AccountPortfolio.FungibleResource,
				isXRD: Bool,
				mode: Mode = .normal
			) {
				self.token = token
				self.isXRD = isXRD
				self.mode = mode
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
				if case let .selection(isSelected) = state.mode {
					state.mode = .selection(isSelected: !isSelected)
					return .none
				}
				return .send(.delegate(.selected(state.token)))
			}
		}
	}
}
