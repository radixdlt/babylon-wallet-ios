import Cryptography
import FeaturePrelude

public struct NameAccount: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Field: String, Sendable, Hashable {
			case entityName
		}

		public var isFirst: Bool
		public var inputtedName: String = "asds"
		public var sanitizedName: NonEmptyString? = "asds"
		public var focusedField: Field?
		public var useLedgerAsFactorSource: Bool

		public init(
			isFirst: Bool,
			inputtedEntityName: String = "",
			sanitizedName: NonEmptyString? = nil,
			focusedField: Field? = nil,
			useLedgerAsFactorSource: Bool = false
		) {
			self.inputtedName = inputtedEntityName
			self.focusedField = focusedField
			self.sanitizedName = sanitizedName
			self.isFirst = isFirst
			self.useLedgerAsFactorSource = useLedgerAsFactorSource
		}

		public init(config: CreateAccountConfig) {
			self.init(isFirst: config.isFirstAccount)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case confirmNameButtonTapped(NonEmptyString)
		case textFieldFocused(State.Field?)
		case textFieldChanged(String)
		case useLedgerAsFactorSourceToggled(Bool)
	}

	public enum InternalAction: Sendable, Equatable {
		case focusTextField(State.Field?)
	}

	public enum DelegateAction: Sendable, Equatable {
		case proceed(accountName: NonEmpty<String>, useLedgerAsFactorSource: Bool)
	}

	@Dependency(\.continuousClock) var clock
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { _ in
//				try await clock.sleep(for: .seconds(0.5))
//				await send(.internal(.focusTextField(.entityName)))
			}

		case let .useLedgerAsFactorSourceToggled(useLedgerAsFactorSource):
			state.useLedgerAsFactorSource = useLedgerAsFactorSource
			return .none

		case let .confirmNameButtonTapped(sanitizedName):
			state.focusedField = nil
			return .run { [useLedgerAsFactorSource = state.useLedgerAsFactorSource] send in
				await send(.delegate(.proceed(
					accountName: sanitizedName,
					useLedgerAsFactorSource: useLedgerAsFactorSource
				)))
			}

		case let .textFieldFocused(focus):
			return .run { send in
				try await clock.sleep(for: .seconds(0.5))
				await send(.internal(.focusTextField(focus)))
			}

		case let .textFieldChanged(inputtedName):
			state.inputtedName = inputtedName
			state.sanitizedName = NonEmpty(rawValue: state.inputtedName.trimmed())
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .focusTextField(focus):
			state.focusedField = focus
			return .none
		}
	}
}
