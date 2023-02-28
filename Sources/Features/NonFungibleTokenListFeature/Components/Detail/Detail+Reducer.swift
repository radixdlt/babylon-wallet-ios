import FeaturePrelude

// MARK: - NonFungibleTokenList.Detail
extension NonFungibleTokenList {
	// MARK: - NonFungibleTokenDetails
	public struct Detail: Sendable, ReducerProtocol {
		@Dependency(\.pasteboardClient) var pasteboardClient

		public init() {}
	}
}

extension NonFungibleTokenList.Detail {
	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.closeButtonTapped)):
			return .run { send in await send(.delegate(.dismiss)) }
		case let .internal(.view(.copyAddressButtonTapped(address))):
			return .run { _ in
				pasteboardClient.copyString(address)
			}
		case .delegate:
			return .none
		}
	}
}
