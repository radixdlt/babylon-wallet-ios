import FeaturePrelude

// MARK: - FungibleTokenDetails
public struct FungibleTokenDetails: Sendable, FeatureReducer {
	public typealias State = FungibleTokenContainer

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case copyAddressButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	@Dependency(\.pasteboardClient) var pasteboardClient

	public init() {}

	public func reduce(into state: inout FungibleTokenContainer, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .send(.delegate(.dismiss))
		case .copyAddressButtonTapped:
			return .run { [address = state.asset.resourceAddress.address] _ in
				pasteboardClient.copyString(address)
			}
		}
	}
}
