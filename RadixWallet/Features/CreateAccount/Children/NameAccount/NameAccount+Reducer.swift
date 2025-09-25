import ComposableArchitecture
import SwiftUI

struct NameAccount: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var isFirst: Bool
		var inputtedName: String
		var sanitizedName: NonEmptyString?

		init(
			isFirst: Bool,
			inputtedEntityName: String = "",
			sanitizedName: NonEmptyString? = nil
		) {
			self.inputtedName = inputtedEntityName
			self.sanitizedName = sanitizedName
			self.isFirst = isFirst
		}

		init(config: CreateAccountConfig) {
			self.init(isFirst: config.isFirstAccount)
		}
	}

	enum ViewAction: Sendable, Equatable {
		case confirmNameButtonTapped(NonEmptyString)
		case textFieldChanged(String)
	}

	enum DelegateAction: Sendable, Equatable {
		case proceed(accountName: NonEmpty<String>)
	}

	@Dependency(\.continuousClock) var clock
	@Dependency(\.errorQueue) var errorQueue

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .confirmNameButtonTapped(sanitizedName):
			return
				.resignFirstResponder
					.concatenate(with: .send(.delegate(.proceed(
						accountName: sanitizedName
					))))

		case let .textFieldChanged(inputtedName):
			state.inputtedName = inputtedName
			state.sanitizedName = NonEmpty(rawValue: state.inputtedName.trimmingWhitespace())
			return .none
		}
	}
}
