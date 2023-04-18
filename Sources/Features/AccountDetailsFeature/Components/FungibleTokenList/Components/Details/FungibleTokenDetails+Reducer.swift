import FeaturePrelude

// MARK: - FungibleTokenDetails
public struct FungibleTokenDetails: Sendable, FeatureReducer {
	public typealias State = AccountPortfolio.FungibleResource

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case copyAddressButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	@Dependency(\.pasteboardClient) var pasteboardClient

	public init() {}

	public func reduce(into state: inout AccountPortfolio.FungibleResource, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .send(.delegate(.dismiss))
		case .copyAddressButtonTapped:
			return .run { [address = state.resourceAddress.address] _ in
				pasteboardClient.copyString(address)
			}
		}
	}
}
