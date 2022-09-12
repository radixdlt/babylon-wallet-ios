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
			tokenRow(viewStore.tokenContainer)
		}
	}

	func tokenRow(_ container: TokenWorthContainer) -> some View {
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
					Text("\(container.token.value ?? 0)")
						.foregroundColor(.app.buttonTextBlack)
						.font(.app.buttonTitle)
					Text("\(container.valueInCurrency ?? 0)")
						.foregroundColor(.app.secondary)
						.font(.app.caption2)
				}
			}
		}
        // TODO: add shadow
		//        .background(Color.green)
		.padding([.leading, .trailing], 18)
		.frame(height: 80)
		//        .background(Color.orange)
		//        .background(Color.white
		//            .shadow(color: .black, radius: 10, x: 10, y: 10)
		//        )
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
