import FeaturePrelude

// MARK: - FungibleTokenDetails
public struct FungibleTokenDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let resource: AccountPortfolio.FungibleResource
		let isXRD: Bool

		public init(resource: AccountPortfolio.FungibleResource, isXRD: Bool) {
			self.resource = resource
			self.isXRD = isXRD
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case copyAddressButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	@Dependency(\.pasteboardClient) var pasteboardClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .send(.delegate(.dismiss))
		case .copyAddressButtonTapped:
			return .run { [address = state.resource.resourceAddress.address] _ in
				pasteboardClient.copyString(address)
			}
		}
	}
}
