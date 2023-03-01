import FeaturePrelude

extension FungibleTokenList.Row.State {
	var viewState: FungibleTokenList.Row.ViewState {
		.init(
			container: container,
			currency: currency,
			isCurrencyAmountVisible: isCurrencyAmountVisible
		)
	}
}

// MARK: - FungibleTokenList.Row.View
extension FungibleTokenList.Row {
	struct ViewState: Equatable {
		let container: FungibleTokenContainer
		let currency: FiatCurrency
		let isCurrencyAmountVisible: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FungibleTokenList.Row>

		public init(store: StoreOf<FungibleTokenList.Row>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ZStack {
					HStack(alignment: .center) {
						HStack(spacing: .small1) {
							LazyImage(url: viewStore.container.asset.iconURL) { _ in
								Image(asset: .placeholderImage(isXRD: viewStore.container.asset.isXRD))
									.resizable()
									.frame(.small)
							}

							Text(viewStore.container.asset.symbol ?? "")
								.foregroundColor(.app.gray1)
								.textStyle(.body2HighImportance)
						}

						Spacer()

						VStack(alignment: .trailing, spacing: .small3) {
							Text(
								tokenAmount(
									amount: viewStore.container.amount,
									isVisible: viewStore.isCurrencyAmountVisible
								)
							)
							.foregroundColor(.app.gray1)
							.textStyle(.secondaryHeader)

							// TODO: uncomment when fiat value ready for implementation
							/*
							 Text(
							 tokenValue(
							 container.worth,
							 isVisible: viewStore.isCurrencyAmountVisible,
							 currency: viewStore.currency
							 )
							 )
							 .foregroundColor(.app.gray2)
							 .textStyle(.body2Regular)
							 */
						}
					}

					VStack {
						Spacer()
						Separator()
					}
				}
				.frame(height: .large1 * 2)
				.padding(.horizontal, .medium1)
				.contentShape(Rectangle())
				.onTapGesture { viewStore.send(.tapped) }
			}
		}
	}
}

// MARK: - Private Methods
extension FungibleTokenList.Row.View {
	fileprivate func tokenAmount(
		amount: BigDecimal?,
		isVisible: Bool
	) -> String {
		guard isVisible else { return "••••" }
		guard let amount else {
			return "-"
		}
		return amount.format()
	}

	fileprivate func tokenValue(_ value: BigDecimal?, isVisible: Bool, currency: FiatCurrency) -> String {
		if isVisible {
			if let value {
				return "\(value.format()) \(currency.symbol)"
			} else {
				return "\(currency.sign) -"
			}
		} else {
			return "\(currency.sign) ••••"
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct Row_Preview: PreviewProvider {
	static var previews: some View {
		FungibleTokenList.Row.View(
			store: .init(
				initialState: .init(
					container: .init(owner: try! .init(address: "owner_address"), asset: .xrd, amount: 100.0, worth: 200),
					currency: .usd,
					isCurrencyAmountVisible: true
				),
				reducer: FungibleTokenList.Row()
			)
		)
	}
}
#endif
