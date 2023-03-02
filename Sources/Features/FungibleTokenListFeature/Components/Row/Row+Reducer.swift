import FeaturePrelude

extension FungibleTokenList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			public var id: FungibleTokenContainer.ID { container.id }

			public var container: FungibleTokenContainer

			// MARK: - AppSettings properties
			public let currency: FiatCurrency
			public var isCurrencyAmountVisible: Bool

			public init(
				container: FungibleTokenContainer,
				currency: FiatCurrency,
				isCurrencyAmountVisible: Bool
			) {
				self.container = container
				self.currency = currency
				self.isCurrencyAmountVisible = isCurrencyAmountVisible
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case tapped
		}

		public enum DelegateAction: Sendable, Equatable {
			case selected(FungibleTokenContainer)
		}

		public init() {}

		public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
			switch viewAction {
			case .tapped:
				return .send(.delegate(.selected(state.container)))
			}
		}
	}
}
