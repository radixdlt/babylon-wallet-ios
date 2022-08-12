import Common
import ComposableArchitecture
import Profile
import SwiftUI

public extension Home.Balance {
	struct View: SwiftUI.View {
		let store: Store<State, Action>
		let account: Account

		public var body: some SwiftUI.View {
			WithViewStore(
				store.scope(
					state: ViewState.init,
					action: Home.Balance.Action.init
				)
			) { viewState in
				VStack {
					title
					BalanceView(
						account: account,
						isBalanceVisible: viewState.isBalanceVisible,
						toggleVisibilityAction: {
							viewState.send(.toggleVisibilityButtonTapped)
						}
					)
				}
			}
		}
	}
}

internal extension Home.Balance.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case toggleVisibilityButtonTapped
	}
}

internal extension Home.Balance.Action {
	init(action: Home.Balance.View.ViewAction) {
		switch action {
		case .toggleVisibilityButtonTapped:
			self = .internal(.user(.toggleVisibilityButtonTapped))
		}
	}
}

extension Home.Balance.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		var isBalanceVisible: Bool

		init(
			state: Home.Balance.State
		) {
			isBalanceVisible = state.isVisible
		}
	}
}

private extension Home.Balance.View {
	var title: some View {
		Text(L10n.Home.Balance.title)
			.foregroundColor(.app.buttonTextBlack)
			.font(.app.caption)
			.textCase(.uppercase)
	}

	struct AmountView: View {
		let isBalanceVisible: Bool
		let account: Account

		var body: some View {
			if isBalanceVisible {
				Text(account.fiatTotalValueString)
					.font(.system(size: 26, weight: .bold))
			} else {
				HStack {
					Text("\(account.accountCurrency.symbol)")
						.foregroundColor(.app.buttonTextBlack)
						.font(.system(size: 26, weight: .bold))

					Text("••••••")
						.foregroundColor(.app.buttonTextLight)
						.font(.system(size: 46, weight: .bold))
						.offset(y: -3)
				}
			}
		}
	}

	struct VisibilityButton: View {
		let isVisible: Bool
		let action: () -> Void

		var body: some View {
			Button(action: action) {
				if isVisible {
					Image("home-balance-shown")
				} else {
					Image("home-balance-hidden")
				}
			}
		}
	}

	struct BalanceView: View {
		let account: Account
		let isBalanceVisible: Bool
		let toggleVisibilityAction: () -> Void

		var body: some View {
			HStack {
				Spacer()
				AmountView(
					isBalanceVisible: isBalanceVisible,
					account: account
				)
				Spacer()
					.frame(width: 44)
				VisibilityButton(
					isVisible: isBalanceVisible,
					action: toggleVisibilityAction
				)
				Spacer()
			}
			.frame(height: 60)
		}
	}
}
