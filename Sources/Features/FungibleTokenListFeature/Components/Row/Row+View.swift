import Asset
import Common
import ComposableArchitecture
import DesignSystem
import Prelude
import Profile

// MARK: - FungibleTokenList.Row.View
public extension FungibleTokenList.Row {
	@MainActor
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
private extension FungibleTokenList.Row.View {
	typealias RowViewStore = ViewStore<FungibleTokenList.Row.View.ViewState, FungibleTokenList.Row.Action.ViewAction>
}

// MARK: - Private Methods
private extension FungibleTokenList.Row.View {
	func tokenRow(with viewStore: RowViewStore, container: FungibleTokenContainer) -> some View {
		ZStack {
			HStack(alignment: .center) {
				HStack(spacing: .small1) {
					LazyImage(url: container.asset.iconURL) { _ in
						Image(asset: container.asset.placeholderImage)
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

	func tokenAmount(
		amount: String?,
		isVisible: Bool
	) -> String {
		guard isVisible else { return "••••" }
		guard let amount else {
			return "-"
		}
		return String(describing: amount)
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
					container: .init(owner: try! .init(address: "owner_address"), asset: .xrd, amount: "100", worth: 200),
					currency: .usd,
					isCurrencyAmountVisible: true
				),
				reducer: FungibleTokenList.Row()
			)
		)
	}
}
