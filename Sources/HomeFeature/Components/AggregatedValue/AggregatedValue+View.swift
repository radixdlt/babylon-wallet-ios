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
			AggregatedValueView(
				value: viewStore.value,
				currency: viewStore.currency,
				isValueVisible: viewStore.isValueVisible,
				toggleVisibilityAction: {
					viewStore.send(.toggleVisibilityButtonTapped)
				}
			)
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
		var value: Float?
		var currency: FiatCurrency // FIXME: this should be currency, since it can be any currency

		init(
			state: Home.AggregatedValue.State
		) {
			isValueVisible = state.isCurrencyAmountVisible
			value = state.value
			currency = state.currency
		}
	}
}

// MARK: - AggregatedValueView
private struct AggregatedValueView: View {
	let value: Float?
	let currency: FiatCurrency
	let isValueVisible: Bool
	let toggleVisibilityAction: () -> Void

	// TODO: is this the right way to handle no value -> 0?
	var amount: Float {
		value ?? 0
	}

	var formattedAmount: String {
		amount.formatted(.currency(code: currency.symbol))
	}

	var body: some View {
		HStack {
			Spacer()
			AmountView(
				isValueVisible: isValueVisible,
				amount: amount,
				formattedAmount: formattedAmount,
				fiatCurrency: currency
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

// MARK: - AmountView
// TODO: extract to separate Feature when view complexity increases
private struct AmountView: View {
	var isValueVisible: Bool
	let amount: Float // NOTE: used for copying the actual value
	let formattedAmount: String
	let fiatCurrency: FiatCurrency

	var body: some View {
		if isValueVisible {
			Text(formattedAmount)
				.foregroundColor(.app.buttonTextBlack)
				.font(.app.titleBold)
		} else {
			HStack {
				Text("\(fiatCurrency.sign)")
					.foregroundColor(.app.buttonTextBlack)
					.font(.app.titleBold)

				Text("••••••")
					.foregroundColor(.app.buttonTextLight)
					.font(.app.largeTitle)
					.offset(y: -3)
			}
		}
	}
}

// MARK: - VisibilityButton
private struct VisibilityButton: View {
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

/*
 // MARK: - AggregatedValue_Preview
 struct AggregatedValue_Preview: PreviewProvider {
 	static var previews: some View {
 		Home.AggregatedValue.View(
 			store: .init(
 				initialState: .placeholder,
 				reducer: Home.AggregatedValue.reducer,
 				environment: .init()
 			)
 		)
 	}
 }
 */
