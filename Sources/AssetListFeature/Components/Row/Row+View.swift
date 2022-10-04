import AccountWorthFetcher
import Common
import ComposableArchitecture
import SwiftUI

// MARK: - AssetList.Row.View
public extension AssetList.Row {
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

public extension AssetList.Row.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: AssetList.Row.Action.init
			)
		) { viewStore in
			tokenRow(with: viewStore, container: viewStore.tokenContainer)
				.padding([.leading, .trailing], 24)
		}
	}
}

// MARK: - AssetList.Row.View.RowViewStore
private extension AssetList.Row.View {
	typealias RowViewStore = ViewStore<AssetList.Row.View.ViewState, AssetList.Row.View.ViewAction>
}

// MARK: - Private Methods
private extension AssetList.Row.View {
	func tokenRow(with viewStore: RowViewStore, container: TokenWorthContainer) -> some View {
		ZStack {
			HStack(alignment: .center) {
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

			VStack {
				Spacer()
				separator()
			}
		}
		.frame(height: 80)
	}

	func separator() -> some View {
		Rectangle()
			.foregroundColor(.app.separatorLightGray)
			.frame(height: 1)
	}

	func tokenAmount(value: Float?, isVisible: Bool) -> String {
		guard isVisible else { return "••••" }
		return value != nil ? "\(value!)" : "-"
	}

	func tokenValue(_ value: Float?, isVisible: Bool, currency: FiatCurrency) -> String {
		if isVisible {
			return value?.formatted(.currency(code: currency.symbol)) ?? "\(currency.sign) -"
		} else {
			return "\(currency.sign) ••••"
		}
	}
}

// MARK: - AssetList.Row.View.ViewAction
extension AssetList.Row.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {}
}

extension AssetList.Row.Action {
	init(action: AssetList.Row.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

// MARK: - AssetList.Row.View.ViewState
extension AssetList.Row.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		let tokenContainer: TokenWorthContainer
		let currency: FiatCurrency
		let isCurrencyAmountVisible: Bool

		init(state: AssetList.Row.State) {
			tokenContainer = state.tokenContainer
			currency = state.currency
			isCurrencyAmountVisible = state.isCurrencyAmountVisible
		}
	}
}

// MARK: - Row_Preview
struct Row_Preview: PreviewProvider {
	static var previews: some View {
		AssetList.Row.View(
			store: .init(
				initialState: .init(
					tokenContainer: .init(
						token: .placeholder,
						valueInCurrency: 100
					),
					currency: .usd,
					isCurrencyAmountVisible: true
				),
				reducer: AssetList.Row.reducer,
				environment: .init()
			)
		)
	}
}
