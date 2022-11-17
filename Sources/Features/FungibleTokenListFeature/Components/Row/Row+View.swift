import Asset
import BigInt
import Common
import ComposableArchitecture
import Profile
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
			store.actionless,
			observe: ViewState.init(state:)
		) { viewStore in
			tokenRow(with: viewStore, container: viewStore.container)
				.padding(.horizontal, .medium1)
		}
	}
}

// MARK: - FungibleTokenList.Row.View.RowViewStore
private extension FungibleTokenList.Row.View {
	typealias RowViewStore = ViewStore<FungibleTokenList.Row.View.ViewState, Never>
}

// MARK: - Private Methods
private extension FungibleTokenList.Row.View {
	func tokenRow(with viewStore: RowViewStore, container: FungibleTokenContainer) -> some View {
		ZStack {
			HStack(alignment: .center) {
				HStack(spacing: .small1) {
					Circle()
						.frame(.small)
						.foregroundColor(.app.gray3)

					Text(container.asset.symbol ?? "")
						.foregroundColor(.app.gray1)
						.textStyle(.body2HighImportance)
				}

				Spacer()

				VStack(alignment: .trailing, spacing: .small3) {
					Text(
						tokenAmount(
							amountInWhole: container.amountInWhole,
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
				separator()
			}
		}
		.frame(height: .large1 * 2)
	}

	func separator() -> some View {
		Rectangle()
			.foregroundColor(.app.gray5)
			.frame(height: 1)
	}

	func tokenAmount(
		amountInWhole: BigUInt?,
		isVisible: Bool
	) -> String {
		guard isVisible else { return "••••" }
		guard let amountInWhole else {
			return "-"
		}
		return String(describing: amountInWhole)
	}

	func tokenValue(_ value: BigUInt?, isVisible: Bool, currency: FiatCurrency) -> String {
		if isVisible {
			return value?.formatted(.currency(code: currency.symbol)) ?? "\(currency.sign) -"
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
					container: .init(asset: .xrd, amountInAttos: 100.inAttos, worth: 200),
					currency: .usd,
					isCurrencyAmountVisible: true
				),
				reducer: FungibleTokenList.Row()
			)
		)
	}
}
