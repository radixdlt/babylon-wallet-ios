import AccountPortfolio
import Asset
import Common
import ComposableArchitecture
import DesignSystem
import FungibleTokenListFeature
import Profile
import SwiftUI

// MARK: - AccountList.Row.View
public extension AccountList.Row {
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

public extension AccountList.Row.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			VStack(alignment: .leading) {
				VStack(alignment: .leading, spacing: .zero) {
					HeaderView(
						name: viewStore.name,
						value: formattedAmmount(
							viewStore.aggregatedValue,
							isVisible: viewStore.isCurrencyAmountVisible,
							currency: viewStore.currency
						),
						isValueVisible: viewStore.isCurrencyAmountVisible,
						currency: viewStore.currency
					)

					AddressView(
						address: viewStore.address.wrapAsAddress(),
						copyAddressAction: {
							viewStore.send(.copyAddressButtonTapped)
						}
					)
					.foregroundColor(.app.whiteTransparent)
					.frame(maxWidth: 160)

					// TODO: replace spacer with token list when API is available
					Spacer()
						.frame(height: 64)
				}
			}
			.padding(.horizontal, .medium1)
			.padding(.vertical, .medium2)
			.background(Color.app.blue2)
			.cornerRadius(.small1)
			.onTapGesture {
				viewStore.send(.selected)
			}
		}
	}
}

// MARK: - Private Methods
private extension AccountList.Row.View {
	func formattedAmmount(_ value: Float?, isVisible: Bool, currency: FiatCurrency) -> String {
		if isVisible {
			return value?.formatted(.currency(code: currency.symbol)) ?? "\(currency.sign) -"
		} else {
			return "\(currency.sign) ••••"
		}
	}
}

// MARK: - AccountList.Row.View.ViewState
extension AccountList.Row.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		let name: String?
		let address: AccountAddress
		let aggregatedValue: Float?
		let currency: FiatCurrency
		let isCurrencyAmountVisible: Bool
		let portfolio: AccountPortfolio

		init(state: AccountList.Row.State) {
			name = state.account.displayName
			address = state.account.address
			aggregatedValue = state.aggregatedValue
			currency = state.currency
			isCurrencyAmountVisible = state.isCurrencyAmountVisible
			portfolio = state.portfolio
		}
	}
}

// MARK: - HeaderView
private struct HeaderView: View {
	let name: String?
	let value: String
	let isValueVisible: Bool
	let currency: FiatCurrency

	var body: some View {
		HStack {
			if let name {
				Text(name)
					.foregroundColor(.app.white)
					.textStyle(.body1Header)
					.fixedSize()
			}
			Spacer()
		}
	}
}

#if DEBUG

// MARK: - Row_Preview
struct Row_Preview: PreviewProvider {
	static var previews: some View {
		registerFonts()

		return AccountList.Row.View(
			store: .init(
				initialState: .placeholder,
				reducer: AccountList.Row()
			)
		)
	}
}
#endif // DEBUG
