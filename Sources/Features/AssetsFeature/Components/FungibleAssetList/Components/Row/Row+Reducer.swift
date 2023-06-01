import FeaturePrelude

extension FungibleAssetList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			public typealias ID = ResourceAddress
			public var id: ID { token.resourceAddress }

			public var token: AccountPortfolio.FungibleResource
			public var isXRD: Bool
			public var isSelected: Bool?

			public init(xrdToken: AccountPortfolio.FungibleResource, isSelected: Bool? = nil) {
				self.init(token: xrdToken, isXRD: true, isSelected: isSelected)
			}

			public init(nonXRDToken: AccountPortfolio.FungibleResource, isSelected: Bool? = nil) {
				self.init(token: nonXRDToken, isXRD: false, isSelected: isSelected)
			}

			init(
				token: AccountPortfolio.FungibleResource,
				isXRD: Bool,
				isSelected: Bool? = nil
			) {
				self.token = token
				self.isXRD = isXRD
				self.isSelected = isSelected
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
				if state.isSelected != nil {
					state.isSelected?.toggle()
					return .none
				}
				return .send(.delegate(.selected(state.token)))
			}
		}
	}
}
