import FeaturePrelude

// MARK: - Decommissioned
public struct Decommissioned: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case openAppStore
	}

	@Dependency(\.openURL) var openURL
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .openAppStore:
			return openAppStore()
		}
	}

	private func openAppStore() -> EffectTask<Action> {
		.run { _ in
			await openURL(
				URL(string: appStoreLink)!
			)
		}
	}
}

// ID of PROD version of app, this was retrieved by clicking "View on App Store" inside App Store Connect
let appStoreLink = "https://apps.apple.com/us/app/radix-wallet/id6448950995"
