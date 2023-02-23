import FeaturePrelude

// MARK: - FungibleTokenDetails
public struct FungibleTokenDetails: Sendable, ReducerProtocol {
	@Dependency(\.pasteboardClient) var pasteboardClient

	public init() {}
}

extension FungibleTokenDetails {
	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.closeButtonTapped)):
			return .send(.delegate(.dismiss))
		case .internal(.view(.copyAddressButtonTapped)):
			return .run { [address = state.asset.componentAddress.address] _ in
				pasteboardClient.copyString(address)
			}
		case .delegate:
			return .none
		}
	}
}
