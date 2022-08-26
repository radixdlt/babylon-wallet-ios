import Common
import ComposableArchitecture
import Profile
import SwiftUI

public extension Home.AccountRow {
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

public extension Home.AccountRow.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Home.AccountRow.Action.init
			)
		) { viewStore in
			VStack(alignment: .leading) {
				VStack(alignment: .leading, spacing: 0) {
					HeaderView(
						name: viewStore.name,
						value: formattedAmmount(
							viewStore.aggregatedValue ?? 0,
							currency: viewStore.currency
						)
					)

					AddressView(
						address: viewStore.address,
						copyAddressAction: {
							viewStore.send(.copyAddressButtonTapped)
						}
					)
					.frame(maxWidth: 160)
				}

				TokenListView(tokens: viewStore.state.tokens)
			}
			.padding(25)
			.background(Color.app.cardBackgroundLight)
			.cornerRadius(6)
			.onTapGesture {
				viewStore.send(.didSelect)
			}
		}
	}

	func formattedAmmount(_ amount: Float, currency: FiatCurrency) -> String {
		amount.formatted(.currency(code: currency.symbol))
	}
}

extension Home.AccountRow.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case copyAddressButtonTapped
		case didSelect
	}
}

extension Home.AccountRow.Action {
	init(action: Home.AccountRow.View.ViewAction) {
		switch action {
		case .copyAddressButtonTapped:
			self = .internal(.user(.copyAddress))
		case .didSelect:
			self = .internal(.user(.didSelect))
		}
	}
}

extension Home.AccountRow.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		let address: Profile.Account.Address
		let aggregatedValue: Float?
		let isValueVisible: Bool
		let currency: FiatCurrency
		let name: String
		let tokens: [Home.AccountRow.Token]

		init(state: Home.AccountRow.State) {
			address = state.address
			aggregatedValue = state.aggregatedValue
			isValueVisible = state.isValueVisible
			currency = state.currency
			name = state.name
			tokens = state.tokens
		}
	}
}

// MARK: - HeaderView
private struct HeaderView: View {
	let name: String
	let value: String

	var body: some View {
		HStack {
			Text(name)
				.foregroundColor(.app.buttonTextBlack)
				.font(.app.buttonTitle)
				.fixedSize()
			Spacer()
			Text(value)
				.foregroundColor(.app.buttonTextBlack)
				.font(.app.buttonTitle)
				.fixedSize()
		}
	}
}

// MARK: - AddressView
struct AddressView: View {
	let address: String
	let copyAddressAction: () -> Void

	var body: some View {
		HStack(spacing: 5) {
			Text(address)
				.lineLimit(1)
				.truncationMode(.middle)
				.foregroundColor(.app.buttonTextBlackTransparent)
				.font(.app.caption2)

			Button(
				action: copyAddressAction,
				label: {
					Text(L10n.Home.AccountRow.copyTitle)
						.foregroundColor(.app.buttonTextBlack)
						.font(.app.caption2)
						.underline()
						.padding(12)
						.fixedSize()
				}
			)
		}
	}
}

// MARK: - TokenView
private struct TokenView: View {
	let code: String

	var body: some View {
		ZStack {
			Circle()
				.strokeBorder(.orange, lineWidth: 1)
				.background(Circle().foregroundColor(Color.App.random))
			Text(code)
				.textCase(.uppercase)
				.foregroundColor(.app.buttonTextBlack)
				.font(.app.footnote)
		}
		.frame(width: 30, height: 30)
	}
}

// MARK: - TokenListView
private struct TokenListView: View {
	let tokens: [Home.AccountRow.Token]
	private let limit = 5

	var body: some View {
		if tokens.count > limit {
			HStack(spacing: -10) {
				ForEach(tokens[0 ..< limit]) { token in
					TokenView(code: token.code.rawValue)
				}
				TokenView(code: "+\(tokens.count - limit)")
			}
		} else {
			HStack(spacing: -10) {
				ForEach(tokens) { token in
					TokenView(code: token.code.rawValue)
				}
			}
		}
	}
}

// MARK: - AccountRow_Preview
struct AccountRow_Preview: PreviewProvider {
	static var previews: some View {
		Home.AccountRow.View(
			store: .init(
				initialState: .radnomTokenPlaceholder,
				reducer: Home.AccountRow.reducer,
				environment: .init()
			)
		)
	}
}
