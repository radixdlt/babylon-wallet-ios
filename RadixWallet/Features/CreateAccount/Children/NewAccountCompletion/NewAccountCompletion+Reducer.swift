import ComposableArchitecture
import SwiftUI

public struct NewAccountCompletion: Sendable, FeatureReducer {
	public struct State: Sendable & Hashable {
		public let account: Account
		public let isFirstOnNetwork: Bool
		public let navigationButtonCTA: CreateAccountNavigationButtonCTA

		public init(
			account: Account,
			isFirstOnNetwork: Bool,
			navigationButtonCTA: CreateAccountNavigationButtonCTA
		) {
			self.account = account
			self.isFirstOnNetwork = isFirstOnNetwork
			self.navigationButtonCTA = navigationButtonCTA
		}

		public init(
			account: Account,
			config: CreateAccountConfig
		) {
			self.init(
				account: account,
				isFirstOnNetwork: config.isFirstAccount,
				navigationButtonCTA: config.navigationButtonCTA
			)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case goToDestination
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .goToDestination:
			.run { send in
				await MainActor.run {
					send(.delegate(.completed))
				}
			}
		}
	}
}
