import ComposableArchitecture
import PasteboardClient

// MARK: - FungibleTokenDetails
public struct FungibleTokenDetails: Sendable, ReducerProtocol {
	@Dependency(\.pasteboardClient) var pasteboardClient

	public init() {}
}

public extension FungibleTokenDetails {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.closeButtonTapped)):
			return .run { send in await send(.delegate(.closeButtonTapped)) }
		case .internal(.view(.copyAddressButtonTapped)):
			return .run { [address = state.asset.componentAddress.address] _ in
				pasteboardClient.copyString(address)
			}
		case .delegate:
			return .none
		}
	}
}
