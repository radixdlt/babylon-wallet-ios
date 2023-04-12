import FeaturePrelude
import FungibleTokenListFeature

extension AccountList.Row.State {
	var viewState: AccountList.Row.ViewState {
		.init(
			name: account.displayName.rawValue,
			address: .init(address: account.address.address, format: .default),
			appearanceID: account.appearanceID
		)
	}
}

// MARK: - AccountList.Row.View
extension AccountList.Row {
	public struct ViewState: Equatable {
		let name: String
		let address: AddressView.ViewState
		let appearanceID: Profile.Network.Account.AppearanceID
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AccountList.Row>

		public init(store: StoreOf<AccountList.Row>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading) {
					VStack(alignment: .leading, spacing: .zero) {
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
					viewStore.send(.tapped)
				}
			}
		}
	}
}

// MARK: - Private Methods
extension AccountList.Row.View {
	fileprivate func formattedAmount(
		_ value: BigDecimal?,
		isVisible: Bool,
		currency: FiatCurrency
	) -> String {
		if isVisible {
			if let value {
				// FIXME: Fix formatting of BigDecimal with symbol
				return "\(currency.symbol) \(value.format())"
			} else {
				return "\(currency.sign) -"
			}
		} else {
			return "\(currency.sign) ••••"
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

extension AccountList.Row.State {
	public static let previewValue = Self(account: .previewValue0)
}
#endif
