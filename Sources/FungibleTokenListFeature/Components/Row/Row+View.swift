import Asset
import Common
import ComposableArchitecture
import SwiftUI

// MARK: - FungibleTokenList.Row.View
public extension FungibleTokenList.Row {
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

public extension FungibleTokenList.Row.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: FungibleTokenList.Row.Action.init
			)
		) { viewStore in
			tokenRow(with: viewStore, container: viewStore.container)
				.padding([.leading, .trailing], 24)
		}
	}
}

// MARK: - FungibleTokenList.Row.View.RowViewStore
private extension FungibleTokenList.Row.View {
	typealias RowViewStore = ViewStore<FungibleTokenList.Row.View.ViewState, FungibleTokenList.Row.View.ViewAction>
}

// MARK: - Private Methods
private extension FungibleTokenList.Row.View {
	func tokenRow(with viewStore: RowViewStore, container: FungibleTokenContainer) -> some View {
		ZStack {
			HStack(alignment: .center) {
				HStack {
					Circle()
						.frame(width: 40, height: 40)
						.foregroundColor(.app.gray3)

					Text(container.asset.code ?? "")
						.foregroundColor(.app.gray2)
						.textStyle(.body2HighImportance)
				}

				Spacer()

				VStack(alignment: .trailing, spacing: 5) {
					Text(tokenAmount(value: container.amount,
					                 isVisible: viewStore.isCurrencyAmountVisible))
						.foregroundColor(.app.buttonTextBlack)
						.textStyle(.secondaryHeader)
					Text(tokenValue(container.worth,
					                isVisible: viewStore.isCurrencyAmountVisible,
					                currency: viewStore.currency))
						.foregroundColor(.app.gray2)
						.textStyle(.body2Regular)
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
			.foregroundColor(.app.gray5)
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

// MARK: - FungibleTokenList.Row.View.ViewAction
extension FungibleTokenList.Row.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {}
}

extension FungibleTokenList.Row.Action {
	init(action: FungibleTokenList.Row.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

// MARK: - FungibleTokenList.Row.View.ViewState
extension FungibleTokenList.Row.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		let container: FungibleTokenContainer
		let currency: FiatCurrency
		let isCurrencyAmountVisible: Bool

		init(state: FungibleTokenList.Row.State) {
			container = state.container
			currency = state.currency
			isCurrencyAmountVisible = state.isCurrencyAmountVisible
		}
	}
}

// MARK: - Row_Preview
struct Row_Preview: PreviewProvider {
	static var previews: some View {
		FungibleTokenList.Row.View(
			store: .init(
				initialState: .init(
					container: .init(asset: .xrd, amount: 100, worth: 200),
					currency: .usd,
					isCurrencyAmountVisible: true
				),
				reducer: FungibleTokenList.Row.reducer,
				environment: .init()
			)
		)
	}
}
