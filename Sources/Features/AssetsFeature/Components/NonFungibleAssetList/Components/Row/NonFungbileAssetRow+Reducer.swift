import EngineKit
import FeaturePrelude

extension NonFungibleAssetList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			public var id: ResourceAddress { resource.resourceAddress }

			public typealias AssetID = AccountPortfolio.NonFungibleResource.NonFungibleToken.ID

			public let resource: AccountPortfolio.NonFungibleResource
			public var isExpanded = false
			public var disabled: Set<AssetID> = []
			public var selectedAssets: OrderedSet<AssetID>?

			public init(
				resource: AccountPortfolio.NonFungibleResource,
				disabled: Set<AssetID> = [],
				selectedAssets: OrderedSet<AssetID>?
			) {
				self.resource = resource
				self.disabled = disabled
				self.selectedAssets = selectedAssets
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case isExpandedToggled
			case assetTapped(State.AssetID)
		}

		public enum DelegateAction: Sendable, Equatable {
			case open(NonFungibleLocalId)
		}

		public init() {}

		public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
			switch viewAction {
			case let .assetTapped(localID):
				guard !state.disabled.contains(localID) else { return .none }
				if state.selectedAssets != nil {
					guard let token = state.resource.tokens[id: localID] else {
						loggerGlobal.warning("Selected a missing token")
						return .none
					}
					state.selectedAssets?.toggle(token.id)
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
