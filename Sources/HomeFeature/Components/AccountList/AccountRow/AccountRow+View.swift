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
						name: viewStore.name ?? "",
						value: formattedAmmount(
							viewStore.aggregatedValue ?? 0,
							currency: viewStore.currency
						)
					)

					AddressView(address: viewStore.address) {
						viewStore.send(.copyAddress)
					}
				}

				HStack(spacing: -10) {
					ForEach(0 ..< .random(in: 1 ... 10)) { _ in
						TokenView()
							.frame(width: 30, height: 30)
					}
				}
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
		case copyAddress
		case didSelect
	}
}

extension Home.AccountRow.Action {
	init(action: Home.AccountRow.View.ViewAction) {
		switch action {
		case .copyAddress:
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
		let currency: FiatCurrency
		let name: String?
		let tokens: [Home.AccountRow.Token]

		init(state: Home.AccountRow.State) {
			address = state.address
			aggregatedValue = state.aggregatedValue
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
private struct AddressView: View {
	let address: String
	let copyAddressAction: () -> Void

	var body: some View {
		HStack(spacing: 0) {
			Text(address)
				.lineLimit(1)
				.truncationMode(.middle)
				.foregroundColor(.app.buttonTextBlackTransparent)
				.font(.app.caption2)
				.frame(maxWidth: 110)

			Button(
				action: copyAddressAction,
				label: {
					Text(L10n.Home.AccountRow.copyTitle)
						.foregroundColor(.app.buttonTextBlack)
						.font(.app.caption2)
						.underline()
						.padding(12)
				}
			)
			Spacer()
		}
	}
}

// MARK: - TokenView
private struct TokenView: View {
	var body: some View {
		ZStack {
			Circle()
				.strokeBorder(.orange, lineWidth: 1)
				.background(Circle().foregroundColor(Color.App.random))
			Text("Rdr")
				.textCase(.uppercase)
				.foregroundColor(.app.buttonTextBlack)
				.font(.app.footnote)
		}
	}
}

// MARK: - AccountRow_Preview
struct AccountRow_Preview: PreviewProvider {
	static var previews: some View {
		Home.AccountRow.View(
			store: .init(
				initialState: .placeholder,
				reducer: Home.AccountRow.reducer,
				environment: .init()
			)
		)
	}
}
