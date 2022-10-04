import AccountPortfolio
import Address
import Asset
import Common
import ComposableArchitecture
import FungibleTokenListFeature
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
			store.scope(
				state: ViewState.init,
				action: AccountList.Row.Action.init
			)
		) { viewStore in
			VStack(alignment: .leading) {
				VStack(alignment: .leading, spacing: 0) {
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
						address: viewStore.address,
						copyAddressAction: {
							viewStore.send(.copyAddressButtonTapped)
						}
					)
					.frame(maxWidth: 160)
				}

				TokenListView(containers: viewStore.state.portfolio.fungibleTokenContainers)
			}
			.padding(25)
			.background(Color.app.cardBackgroundLight)
			.cornerRadius(6)
			.onTapGesture {
				viewStore.send(.didSelect)
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

// MARK: - AccountList.Row.View.ViewAction
extension AccountList.Row.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case copyAddressButtonTapped
		case didSelect
	}
}

extension AccountList.Row.Action {
	init(action: AccountList.Row.View.ViewAction) {
		switch action {
		case .copyAddressButtonTapped:
			self = .internal(.user(.copyAddress))
		case .didSelect:
			self = .internal(.user(.didSelect))
		}
	}
}

// MARK: - AccountList.Row.View.ViewState
extension AccountList.Row.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		let name: String
		let address: Address
		let aggregatedValue: Float?
		let currency: FiatCurrency
		let isCurrencyAmountVisible: Bool
		let portfolio: AccountPortfolio

		init(state: AccountList.Row.State) {
			name = state.name
			address = state.address
			aggregatedValue = state.aggregatedValue
			currency = state.currency
			isCurrencyAmountVisible = state.isCurrencyAmountVisible
			portfolio = state.portfolio
		}
	}
}

// MARK: - HeaderView
private struct HeaderView: View {
	let name: String
	let value: String
	let isValueVisible: Bool
	let currency: FiatCurrency

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
	private let sortedTokens: [FungibleTokenContainer]
	private let limit = 5

	init(containers: [FungibleTokenContainer]) {
		sortedTokens = FungibleTokenListSorter.live.sortTokens(containers).map(\.tokenContainers).flatMap { $0 }
	}

	var body: some View {
		if sortedTokens.count > limit {
			HStack(spacing: -10) {
				ForEach(sortedTokens[0 ..< limit]) { token in
					TokenView(code: token.asset.code ?? "")
				}
				TokenView(code: "+\(sortedTokens.count - limit)")
			}
		} else {
			HStack(spacing: -10) {
				ForEach(sortedTokens) { token in
					TokenView(code: token.asset.code ?? "")
				}
			}
		}
	}
}

// MARK: - Row_Preview
struct Row_Preview: PreviewProvider {
	static var previews: some View {
		AccountList.Row.View(
			store: .init(
				initialState: .placeholder,
				reducer: AccountList.Row.reducer,
				environment: .init()
			)
		)
	}
}
