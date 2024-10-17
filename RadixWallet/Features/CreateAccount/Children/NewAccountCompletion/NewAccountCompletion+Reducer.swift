import ComposableArchitecture
import SwiftUI

struct NewAccountCompletion: Sendable, FeatureReducer {
	struct State: Sendable & Hashable {
		let account: Account
		let isFirstOnNetwork: Bool
		let navigationButtonCTA: CreateAccountNavigationButtonCTA

		init(
			account: Account,
			isFirstOnNetwork: Bool,
			navigationButtonCTA: CreateAccountNavigationButtonCTA
		) {
			self.account = account
			self.isFirstOnNetwork = isFirstOnNetwork
			self.navigationButtonCTA = navigationButtonCTA
		}

		init(
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

	enum ViewAction: Sendable, Equatable {
		case goToDestination
	}

	enum DelegateAction: Sendable, Equatable {
		case completed
	}

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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
