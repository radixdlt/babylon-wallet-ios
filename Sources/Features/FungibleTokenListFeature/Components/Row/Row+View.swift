import FeaturePrelude

extension FungibleTokenList.Row.State {
	var viewState: FungibleTokenList.Row.ViewState {
		.init(
			isXRD: container.asset.isXRD,
			iconURL: container.asset.iconURL,
			symbol: container.asset.symbol ?? "",
			tokenAmount: {
				if isCurrencyAmountVisible {
					return container.amount.format()
				} else {
					return "••••"
				}
			}(),
			tokenValue: {
				if isCurrencyAmountVisible {
					if let value = container.worth {
						return "\(value.format()) \(currency.symbol)"
					} else {
						return "\(currency.sign) -"
					}
				} else {
					return "\(currency.sign) ••••"
				}
			}()
		)
	}
}

// MARK: - FungibleTokenList.Row.View
extension FungibleTokenList.Row {
	struct ViewState: Equatable {
		let isXRD: Bool
		let iconURL: URL?
		let symbol: String
		let tokenAmount: String
		let tokenValue: String
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
							LazyImage(url: viewStore.iconURL) { _ in
								Image(asset: .placeholderImage(isXRD: viewStore.isXRD))
									.resizable()
									.frame(.small)
							}

							Text(viewStore.symbol)
								.foregroundColor(.app.gray1)
								.textStyle(.body2HighImportance)
						}

						Spacer()

						VStack(alignment: .trailing, spacing: .small3) {
							Text(viewStore.tokenAmount)
								.foregroundColor(.app.gray1)
								.textStyle(.secondaryHeader)

							// TODO: uncomment when fiat value ready for implementation
							/*
							 Text(viewStore.tokenValue)
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
