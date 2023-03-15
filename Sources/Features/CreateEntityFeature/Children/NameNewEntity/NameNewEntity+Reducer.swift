import Cryptography
import FeaturePrelude

// MARK: - NameNewEntity
public struct NameNewEntity<Entity: EntityProtocol>: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Field: String, Sendable, Hashable {
			case entityName
		}

		public var isFirst: Bool
		public var inputtedName: String
		public var sanitizedName: NonEmptyString?
		public var focusedField: Field?

		public init(
			isFirst: Bool,
			inputtedEntityName: String = "",
			sanitizedName: NonEmptyString? = nil,
			focusedField: Field? = nil
		) {
			self.inputtedName = inputtedEntityName
			self.focusedField = focusedField
			self.sanitizedName = sanitizedName
			self.isFirst = isFirst
		}

		public init(config: CreateEntityConfig) {
			self.init(isFirst: config.isFirstEntity)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case confirmNameButtonTapped
		case textFieldFocused(State.Field?)
		case textFieldChanged(String)
	}

	public enum InternalAction: Sendable, Equatable {
		case focusTextField(State.Field?)
	}

	public enum DelegateAction: Sendable, Equatable {
		case named(NonEmpty<String>)
	}

	@Dependency(\.continuousClock) var clock
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				try await clock.sleep(for: .seconds(0.5))
				await send(.internal(.focusTextField(.entityName)))
			}

		case .confirmNameButtonTapped:
			guard let sanitizedName = state.sanitizedName else {
				return .none
			}
			state.focusedField = nil
			return .run { send in
				await send(.delegate(.named(sanitizedName)))
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
