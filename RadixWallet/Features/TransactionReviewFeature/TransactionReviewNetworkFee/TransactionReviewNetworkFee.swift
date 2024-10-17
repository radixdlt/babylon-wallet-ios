import ComposableArchitecture
import SwiftUI

// MARK: - TransactionReviewNetworkFee
struct TransactionReviewNetworkFee: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var reviewedTransaction: ReviewedTransaction
		var fiatValue: Loadable<String> = .idle
		let id: UUID

		init(
			reviewedTransaction: ReviewedTransaction
		) {
			self.reviewedTransaction = reviewedTransaction
			self.id = .init()
		}
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case customizeTapped
	}

	enum InternalAction: Sendable, Equatable {
		case setTokenPrices(TaskResult<PriceResult>)
	}

	enum DelegateAction: Sendable, Equatable {
		case showCustomizeFees
	}

	struct PriceResult: Sendable, Equatable {
		let prices: TokenPricesClient.TokenPrices
		let currency: FiatCurrency
	}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.tokenPricesClient) var tokenPricesClient
	@Dependency(\.errorQueue) var errorQueue

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			state.fiatValue = .loading
			return .run { send in
				let currency = await appPreferencesClient.getPreferences().display.fiatCurrencyPriceTarget
				let result = await TaskResult {
					let prices = try await tokenPricesClient.getTokenPrices(.init(tokens: [.mainnetXRD], currency: currency), false)
					return PriceResult(prices: prices, currency: currency)
				}
				await send(.internal(.setTokenPrices(result)))
			}
		case .customizeTapped:
			return .send(.delegate(.showCustomizeFees))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setTokenPrices(.failure(error)):
			loggerGlobal.error("TransactionReviewNetworkFee failed to fetch XRD price, error: \(error)")
			state.fiatValue = .failure(error)
			return .none

		case let .setTokenPrices(.success(result)):
			guard let price = result.prices[.mainnetXRD] else {
				loggerGlobal.error("TransactionReviewNetworkFee didn't get XRD price on response")
				state.fiatValue = .failure(MissingXrdPriceError())
				return .none
			}
			state.fiatValue = .success(state.reviewedTransaction.transactionFee.totalFee.fiatValue(xrdPrice: price, currency: result.currency))
			return .none
		}
	}

	private struct MissingXrdPriceError: Error {}
}

private extension TransactionFee.TotalFee {
	func fiatValue(xrdPrice: Decimal192, currency: FiatCurrency) -> String {
		let formatter = Self.feePriceFormatter
		formatter.currencyCode = currency.currencyCode

		let maxPrice = max * xrdPrice
		let maxValue = formatter.string(for: maxPrice.asDouble) ?? maxPrice.formatted()
		guard max > min else {
			return maxValue
		}

		let minPrice = min * xrdPrice
		let minValue = formatter.string(for: minPrice.asDouble) ?? minPrice.formatted()
		return "\(minValue) - \(maxValue)"
	}

	private static let feePriceFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.maximumSignificantDigits = 3
		return formatter
	}()
}
