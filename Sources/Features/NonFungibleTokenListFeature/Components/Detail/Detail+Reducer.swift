import ComposableArchitecture
import PasteboardClient

// MARK: - NonFungibleTokenList.Detail
public extension NonFungibleTokenList {
	// MARK: - NonFungibleTokenDetails
	struct Detail: ReducerProtocol {
		@Dependency(\.pasteboardClient) var pasteboardClient

		public init() {}
	}
}

public extension NonFungibleTokenList.Detail {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.closeButtonTapped)):
			return .run { send in await send(.delegate(.closeButtonTapped)) }
		case .internal(.view(.copyAddressButtonTapped)):
			return .run { [address = state.container.resourceAddress.address] _ in
				pasteboardClient.copyString(address)
			}
		case .delegate:
			return .none
		}
	}
}
