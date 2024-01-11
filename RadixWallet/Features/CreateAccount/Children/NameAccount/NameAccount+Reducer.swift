import ComposableArchitecture
import SwiftUI

public struct NameAccount: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var isFirst: Bool
		public var inputtedName: String
		public var sanitizedName: NonEmptyString?
		public var useLedgerAsFactorSource: Bool

		public init(
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

		public init(config: CreateAccountConfig) {
			self.init(isFirst: config.isFirstAccount)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case confirmNameButtonTapped(NonEmptyString)
		case textFieldChanged(String)
		case useLedgerAsFactorSourceToggled(Bool)
	}

	public enum DelegateAction: Sendable, Equatable {
		case proceed(accountName: NonEmpty<String>, useLedgerAsFactorSource: Bool)
	}

	@Dependency(\.continuousClock) var clock
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .useLedgerAsFactorSourceToggled(useLedgerAsFactorSource):
			state.useLedgerAsFactorSource = useLedgerAsFactorSource
			return .none

		case let .confirmNameButtonTapped(sanitizedName):
			return .send(.delegate(.proceed(
				accountName: sanitizedName,
				useLedgerAsFactorSource: state.useLedgerAsFactorSource
			)))

		case let .textFieldChanged(inputtedName):
			state.inputtedName = inputtedName
			state.sanitizedName = NonEmpty(rawValue: state.inputtedName.trimmingWhitespace())
			return .none
		}
	}
}
