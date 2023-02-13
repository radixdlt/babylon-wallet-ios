import AccountPortfolio
import FeaturePrelude
import FungibleTokenListFeature

// MARK: - AccountList.Row.View
extension AccountList.Row {
	@MainActor
	public struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(
			store: Store
		) {
			self.store = store
		}
	}
}

extension AccountList.Row.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			VStack(alignment: .leading) {
				VStack(alignment: .leading, spacing: .zero) {
					HeaderView(
						name: viewStore.name,
						value: formattedAmount(
							viewStore.aggregatedValue,
							isVisible: viewStore.isCurrencyAmountVisible,
							currency: viewStore.currency
						),
						isValueVisible: viewStore.isCurrencyAmountVisible,
						currency: viewStore.currency
					)

					AddressView(
						viewStore.address,
						copyAddressAction: {
							viewStore.send(.copyAddressButtonTapped)
						}
					)
					.foregroundColor(.app.whiteTransparent)

					// TODO: replace spacer with token list when API is available
					Spacer()
						.frame(height: 64)
				}
			}
			.padding(.horizontal, .medium1)
			.padding(.vertical, .medium2)
			.background(viewStore.appearanceID.gradient)
			.cornerRadius(.small1)
			.onTapGesture {
				viewStore.send(.selected)
			}
		}
	}
}

// MARK: - Private Methods
extension AccountList.Row.View {
	fileprivate func formattedAmount(_ value: BigDecimal?, isVisible: Bool, currency: FiatCurrency) -> String {
		if isVisible {
			if let value {
				// FIXME: Fix formatting of BigDecimal with symbol
				return "\(currency.symbol) \(String(describing: value))"
			} else {
				return "\(currency.sign) -"
			}
		} else {
			return "\(currency.sign) ••••"
		}
	}
}

// MARK: - AccountList.Row.View.ViewState
extension AccountList.Row.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		let name: String
		let address: AddressView.ViewState
		let appearanceID: OnNetwork.Account.AppearanceID
		let aggregatedValue: BigDecimal?
		let currency: FiatCurrency
		let isCurrencyAmountVisible: Bool
		let portfolio: AccountPortfolio

		init(state: AccountList.Row.State) {
			name = state.account.displayName.rawValue
			address = .init(address: state.account.address.address, format: .short())
			appearanceID = state.account.appearanceID
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
import SwiftUI // NB: necessary for previews to appear

struct Row_Preview: PreviewProvider {
	static var previews: some View {
		AccountList.Row.View(
			store: .init(
				initialState: .previewValue,
				reducer: AccountList.Row()
			)
		)
	}
}
#endif
