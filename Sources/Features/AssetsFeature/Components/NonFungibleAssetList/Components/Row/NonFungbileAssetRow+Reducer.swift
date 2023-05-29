import FeaturePrelude

extension NonFungibleAssetList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			public var id: ResourceAddress { resource.resourceAddress }

			public typealias SelectedAssets = IdentifiedArrayOf<AccountPortfolio.NonFungibleResource.NonFungibleToken>

			public let resource: AccountPortfolio.NonFungibleResource
			public var isExpanded = false
			public var selectedAssets: SelectedAssets?

			public init(
				resource: AccountPortfolio.NonFungibleResource,
				selectedAssets: SelectedAssets?
			) {
				self.resource = resource
				self.selectedAssets = selectedAssets
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case isExpandedToggled
			case assetTapped(AccountPortfolio.NonFungibleResource.NonFungibleToken.LocalID)
		}

		public enum DelegateAction: Sendable, Equatable {
			case open(AccountPortfolio.NonFungibleResource.NonFungibleToken.LocalID)
		}

		public init() {}

		public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
			switch viewAction {
			case let .assetTapped(localID):
				if state.selectedAssets != nil {
					guard let token = state.resource.tokens[id: localID] else {
						loggerGlobal.warning("Selected a missing token")
						return .none
					}
					state.selectedAssets?.toggle(token)
					return .none
				}
				return .send(.delegate(.open(localID)))

			case .isExpandedToggled:
				state.isExpanded.toggle()
				return .none
			}
		}
	}
}
