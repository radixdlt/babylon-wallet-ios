import FeaturePrelude

extension AggregatedValue.State {
	var viewState: AggregatedValue.ViewState {
		.init(
			isValueVisible: isCurrencyAmountVisible,
			value: value,
			currency: currency
		)
	}
}

// MARK: - AggregatedValue.View
extension AggregatedValue {
	public struct ViewState: Equatable {
		let isValueVisible: Bool
		let value: BigDecimal?
		let currency: FiatCurrency // FIXME: this should be currency, since it can be any currency
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AggregatedValue>

		public init(store: StoreOf<AggregatedValue>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
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
}

// MARK: - AggregatedValueView
private struct AggregatedValueView: View {
	let value: BigDecimal?
	let currency: FiatCurrency
	let isValueVisible: Bool
	let toggleVisibilityAction: () -> Void

	// TODO: is this the right way to handle no value -> 0?
	var amount: BigDecimal {
		value ?? 0
	}

	var formattedAmount: String {
		amount.format()
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
	let amount: BigDecimal // NOTE: used for copying the actual value
	let formattedAmount: String
	let fiatCurrency: FiatCurrency

	var body: some View {
		if isValueVisible {
			Text(formattedAmount)
				.foregroundColor(.app.buttonTextBlack)
				.textStyle(.sectionHeader)
		} else {
			HStack {
				Text("\(fiatCurrency.sign)")
					.foregroundColor(.app.buttonTextBlack)
					.textStyle(.sectionHeader)

				Text("••••••")
					.foregroundColor(.app.gray4)
					.textStyle(.sheetTitle)
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
				Image(asset: AssetResource.homeAggregatedValueShown)
			} else {
				Image(asset: AssetResource.homeAggregatedValueHidden)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct AggregatedValue_Preview: PreviewProvider {
	static var previews: some View {
		AggregatedValue.View(
			store: .init(
				initialState: .previewValue,
				reducer: AggregatedValue()
			)
		)
	}
}

extension AggregatedValue.State {
	public static let previewValue = AggregatedValue.State(
		value: 1_000_000,
		currency: .usd
	)
}
#endif
