import FeaturePrelude

// MARK: - FungibleTokenList.Row.View
extension FungibleTokenList.Row {
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

extension FungibleTokenList.Row.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			tokenRow(with: viewStore, container: viewStore.container)
				.padding(.horizontal, .medium1)
				.contentShape(Rectangle())
				.onTapGesture { viewStore.send(.selected) }
		}
	}
}

// MARK: - FungibleTokenList.Row.View.RowViewStore
extension FungibleTokenList.Row.View {
	fileprivate typealias RowViewStore = ViewStore<FungibleTokenList.Row.View.ViewState, FungibleTokenList.Row.Action.ViewAction>
}

// MARK: - Private Methods
extension FungibleTokenList.Row.View {
	fileprivate func tokenRow(with viewStore: RowViewStore, container: FungibleTokenContainer) -> some View {
		ZStack {
			HStack(alignment: .center) {
				HStack(spacing: .small1) {
					LazyImage(url: container.asset.iconURL) { _ in
						Image(asset: .placeholderImage(isXRD: viewStore.container.asset.isXRD))
							.resizable()
							.frame(.small)
					}

					Text(container.asset.symbol ?? "")
						.foregroundColor(.app.gray1)
						.textStyle(.body2HighImportance)
				}

				Spacer()

				VStack(alignment: .trailing, spacing: .small3) {
					Text(
						tokenAmount(
							amount: container.amount,
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
	}

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
			if let value = value, let doubleValue = Double(value.description) {
				return doubleValue.formatted(.currency(code: currency.symbol))
			} else {
				return "\(currency.sign) -"
			}
		} else {
			return "\(currency.sign) ••••"
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
			self.container = state.container
			self.currency = state.currency
			self.isCurrencyAmountVisible = state.isCurrencyAmountVisible
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
