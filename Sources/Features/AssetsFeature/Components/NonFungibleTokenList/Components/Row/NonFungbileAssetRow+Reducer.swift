import FeaturePrelude

extension NonFungibleTokenList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			public var id: ResourceAddress { resource.resourceAddress }

			public enum Mode: Hashable, Sendable {
				case normal
				case selection(IdentifiedArrayOf<AccountPortfolio.NonFungibleResource.NonFungibleToken>)
			}

			public let resource: AccountPortfolio.NonFungibleResource
			public var isExpanded = false
			public var mode: Mode = .selection([])

			public init(
				resource: AccountPortfolio.NonFungibleResource,
				mode: Mode
			) {
				self.resource = resource
				self.mode = mode
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
				if case var .selection(selectedItems) = state.mode {
					guard let token = state.resource.tokens[id: localID] else {
						return .none
					}

					if selectedItems.contains(token) {
						selectedItems.remove(token)
					} else {
						selectedItems.append(token)
					}
					state.mode = .selection(selectedItems)
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
