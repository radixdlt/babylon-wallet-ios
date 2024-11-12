import ComposableArchitecture
import SwiftUI

struct NameAccount: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var isFirst: Bool
		var inputtedName: String
		var sanitizedName: NonEmptyString?
		var useLedgerAsFactorSource: Bool

		init(
			isFirst: Bool,
			inputtedEntityName: String = "",
			sanitizedName: NonEmptyString? = nil,
			useLedgerAsFactorSource: Bool = false
		) {
			self.inputtedName = inputtedEntityName
			self.sanitizedName = sanitizedName
			self.isFirst = isFirst
			self.useLedgerAsFactorSource = useLedgerAsFactorSource
		}

		init(config: CreateAccountConfig) {
			self.init(isFirst: config.isFirstAccount)
		}
	}

	enum ViewAction: Sendable, Equatable {
		case confirmNameButtonTapped(NonEmptyString)
		case textFieldChanged(String)
		case useLedgerAsFactorSourceToggled(Bool)
	}

	enum DelegateAction: Sendable, Equatable {
		case proceed(accountName: NonEmpty<String>, useLedgerAsFactorSource: Bool)
	}

	@Dependency(\.continuousClock) var clock
	@Dependency(\.errorQueue) var errorQueue

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .useLedgerAsFactorSourceToggled(useLedgerAsFactorSource):
			state.useLedgerAsFactorSource = useLedgerAsFactorSource
			return .none

		case let .confirmNameButtonTapped(sanitizedName):
			return
				.resignFirstResponder
					.concatenate(with: .send(.delegate(.proceed(
						accountName: sanitizedName,
						useLedgerAsFactorSource: state.useLedgerAsFactorSource
					))))

		case let .textFieldChanged(inputtedName):
			state.inputtedName = inputtedName
			state.sanitizedName = NonEmpty(rawValue: state.inputtedName.trimmingWhitespace())
			return .none
		}
	}
}
