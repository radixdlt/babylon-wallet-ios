import Common
import ComposableArchitecture
import Profile
import SwiftUI

public extension Home.AggregatedValue {
	struct View: SwiftUI.View {
		let store: Store<State, Action>
	}
}

public extension Home.AggregatedValue.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Home.AggregatedValue.Action.init
			)
		) { viewStore in
			VStack {
				title
				AggregatedValueView(
					account: viewStore.account,
					isValueVisible: viewStore.isValueVisible,
					toggleVisibilityAction: {
						viewStore.send(.toggleVisibilityButtonTapped)
					}
				)
			}
		}
	}
}

extension Home.AggregatedValue.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case toggleVisibilityButtonTapped
	}
}

extension Home.AggregatedValue.Action {
	init(action: Home.AggregatedValue.View.ViewAction) {
		switch action {
		case .toggleVisibilityButtonTapped:
			self = .internal(.user(.toggleVisibilityButtonTapped))
		}
	}
}

extension Home.AggregatedValue.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		var isValueVisible: Bool
		var account: Account

		init(
			state: Home.AggregatedValue.State
		) {
			isValueVisible = state.isVisible
			account = state.account
		}
	}
}

private extension Home.AggregatedValue.View {
	var title: some View {
		Text(L10n.Home.AggregatedValue.title)
			.foregroundColor(.app.buttonTextBlack)
			.font(.app.caption)
			.textCase(.uppercase)
	}

	// TODO: extract to separate Feature when view complexity increases
	struct AmountView: View {
		let isValueVisible: Bool
		let amount: Float // NOTE: used for copying the actual value
		let formattedAmount: String
		let fiatCurrency: FiatCurrency

		var body: some View {
			if isValueVisible {
				Text(formattedAmount)
					.font(.system(size: 26, weight: .bold))
			} else {
				HStack {
					Text("\(fiatCurrency.symbol)")
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
					Image("home-aggregatedValue-shown")
				} else {
					Image("home-aggregatedValue-hidden")
				}
			}
		}
	}

	struct AggregatedValueView: View {
		let account: Account
		let isValueVisible: Bool
		let toggleVisibilityAction: () -> Void

		var body: some View {
			HStack {
				Spacer()
				// FIXME: currency
				AmountView(
					isValueVisible: isValueVisible,
					amount: 0,
					formattedAmount: "0",
					fiatCurrency: FiatCurrency.usd
				)
				Spacer()
					.frame(width: 44)
				VisibilityButton(
					isVisible: isValueVisible,
					action: toggleVisibilityAction
				)
				Spacer()
			}
			.frame(height: 60)
		}
	}
}
