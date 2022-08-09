import Common
import ComposableArchitecture
import SwiftUI

public extension Home.Balance {
	struct View: SwiftUI.View {
		let store: Store<State, Action>

		public var body: some SwiftUI.View {
			WithViewStore(
				store.scope(
					state: ViewState.init,
					action: Home.Balance.Action.init
				)
			) { viewState in
				VStack {
					title
					BalanceView(isBalanceVisible: viewState.isBalanceVisible,
					            action: { viewState.send(.toggleVisibilityButtonTapped) })
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

		init(state: Home.Balance.State) {
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

	struct Amount: View {
		var body: some View {
			HStack {
				Text("$")
					.foregroundColor(.app.buttonTextBlack)
					.font(.system(size: 26, weight: .bold))
				Text("••••••")
					.foregroundColor(.app.buttonTextLight)
					.font(.system(size: 46, weight: .bold))
					.offset(y: -3)
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
		let isBalanceVisible: Bool
		let action: () -> Void

		var body: some View {
			HStack(spacing: 0) {
				Spacer()
				Amount()
				Spacer(minLength: 44)
				VisibilityButton(isVisible: isBalanceVisible,
				                 action: action)
				Spacer()
			}
		}
	}
}
