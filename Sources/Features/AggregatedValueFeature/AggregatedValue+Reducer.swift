import FeaturePrelude

public struct AggregatedValue: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var value: BigDecimal?

		// MARK: - AppSettings properties
		public var currency: FiatCurrency
		public var isCurrencyAmountVisible: Bool

		public init(
			value: BigDecimal? = nil,
			currency: FiatCurrency = .usd,
			isCurrencyAmountVisible: Bool = false
		) {
			self.value = value
			self.currency = currency
			self.isCurrencyAmountVisible = isCurrencyAmountVisible
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case toggleVisibilityButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case toggleIsCurrencyAmountVisible
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .toggleVisibilityButtonTapped:
			return .send(.delegate(.toggleIsCurrencyAmountVisible))
		}
	}
}
