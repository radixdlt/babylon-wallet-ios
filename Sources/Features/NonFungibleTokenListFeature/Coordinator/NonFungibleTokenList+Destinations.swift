import FeaturePrelude

extension NonFungibleTokenList {
	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case details(NonFungibleTokenList.Detail.State)
		}

		public enum Action: Sendable, Equatable {
			case details(NonFungibleTokenList.Detail.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.details, action: /Action.details) {
				NonFungibleTokenList.Detail()
			}
		}
	}
}
