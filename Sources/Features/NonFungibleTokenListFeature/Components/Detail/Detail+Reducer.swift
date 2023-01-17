import FeaturePrelude

// MARK: - NonFungibleTokenList.Detail
public extension NonFungibleTokenList {
	// MARK: - NonFungibleTokenDetails
	struct Detail: Sendable, ReducerProtocol {
		@Dependency(\.pasteboardClient) var pasteboardClient

		public init() {}
	}
}

public extension NonFungibleTokenList.Detail {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.closeButtonTapped)):
			return .run { send in await send(.delegate(.closeButtonTapped)) }
		case let .internal(.view(.copyAddressButtonTapped(address))):
			return .run { _ in
				pasteboardClient.copyString(address)
			}
		case .delegate:
			return .none
		}
	}
}
