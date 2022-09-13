import AccountWorthFetcher
import Common
import ComposableArchitecture
import SwiftUI

public extension Home.AssetRow {
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(
			store: Store
		) {
			self.store = store
		}
	}
}

public extension Home.AssetRow.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Home.AssetRow.Action.init
			)
		) { viewStore in
			tokenRow(with: viewStore, container: viewStore.tokenContainer)
				.padding([.leading, .trailing], 24)
		}
	}
}

// MARK: - Private Typealias
private extension Home.AssetRow.View {
	typealias AssetRowViewStore = ViewStore<Home.AssetRow.View.ViewState, Home.AssetRow.View.ViewAction>
}

// MARK: - Private Methods
private extension Home.AssetRow.View {
	func tokenRow(with viewStore: AssetRowViewStore, container: TokenWorthContainer) -> some View {
		VStack {
			HStack {
				HStack {
					Circle()
						.frame(width: 40, height: 40)
						.foregroundColor(.app.tokenPlaceholderGray)

					Text(container.token.code.value)
						.foregroundColor(.app.secondary)
						.font(.app.subhead)
				}

				Spacer()

				VStack(alignment: .trailing, spacing: 5) {
					Text(tokenAmount(value: container.token.value,
					                 isVisible: viewStore.isCurrencyAmountVisible))
						.foregroundColor(.app.buttonTextBlack)
						.font(.app.buttonTitle)
					Text(tokenValue(container.valueInCurrency,
					                isVisible: viewStore.isCurrencyAmountVisible,
					                currency: viewStore.currency))
						.foregroundColor(.app.secondary)
						.font(.app.caption2)
				}
			}
		}
//		.padding([.leading, .trailing], 18)
		.frame(height: 80)
		/*
		 .if(container.token.code == .xrd, transform: { view in
		 	view
		 		.background(
		 			RoundedRectangle(cornerRadius: 6)
		 				.fill(Color.white)
		 				.shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 9)
		 		)
		 })
		 */
	}

	func tokenAmount(value: Float?, isVisible: Bool) -> String {
		if isVisible {
			if let value = value {
				return "\(value)"
			} else {
				return "-"
			}
		} else {
			return "••••"
		}
	}

	func tokenValue(_ value: Float?, isVisible: Bool, currency: FiatCurrency) -> String {
		if isVisible {
			return value?.formatted(.currency(code: currency.symbol)) ?? "\(currency.sign)-"
		} else {
			return "\(currency.sign) ••••"
		}
	}
}

extension Home.AssetRow.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {}
}

extension Home.AssetRow.Action {
	init(action: Home.AssetRow.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

extension Home.AssetRow.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		let tokenContainer: TokenWorthContainer
		let currency: FiatCurrency
		let isCurrencyAmountVisible: Bool

		init(state: Home.AssetRow.State) {
			tokenContainer = state.tokenContainer
			currency = state.currency
			isCurrencyAmountVisible = state.isCurrencyAmountVisible
		}
	}
}

// MARK: - AssetRow_Preview
struct AssetRow_Preview: PreviewProvider {
	static var previews: some View {
		Home.AssetRow.View(
			store: .init(
				initialState: .init(
					id: UUID(),
					tokenContainer: .init(
						token: .placeholder,
						valueInCurrency: 100
					),
					currency: .usd,
					isCurrencyAmountVisible: true
				),
				reducer: Home.AssetRow.reducer,
				environment: .init()
			)
		)
	}
}

extension View {
	/// Applies the given transform if the given condition evaluates to `true`.
	/// - Parameters:
	///   - condition: The condition to evaluate.
	///   - transform: The transform to apply to the source `View`.
	/// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
	@ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
		if condition {
			transform(self)
		} else {
			self
		}
	}
}
