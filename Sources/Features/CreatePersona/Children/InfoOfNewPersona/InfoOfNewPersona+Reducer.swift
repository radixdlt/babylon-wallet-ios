import Cryptography
import FeaturePrelude

public struct NewPersonaInfo: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum InputField: String, Sendable, Hashable {
			case personaName
		}

		public var isFirstPersona: Bool
		public var inputtedName: String
		public var sanitizedName: NonEmptyString?

		// FIXME: Build support for input of persona "fields"/"entries"!
		public var personaData: PersonaData
		public var focusedInputField: InputField?

		public init(
			isFirstPersona: Bool,
			inputtedEntityName: String = "",
			sanitizedName: NonEmptyString? = nil,
			personaData: PersonaData = .init(),
			focusedInputField: InputField? = nil
		) {
			self.inputtedName = inputtedEntityName
			self.focusedInputField = focusedInputField
			self.sanitizedName = sanitizedName
			self.isFirstPersona = isFirstPersona
			self.personaData = personaData
		}

		public init(config: CreatePersonaConfig) {
			self.init(isFirstPersona: config.personaPrimacy.firstPersonaOnCurrentNetwork)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case confirmNameButtonTapped(NonEmptyString)
		case textFieldFocused(State.InputField?)
		case textFieldChanged(String)
	}

	public enum InternalAction: Sendable, Equatable {
		case focusTextField(State.InputField?)
	}

	public enum DelegateAction: Sendable, Equatable {
		case proceed(
			personaName: NonEmptyString,
			personaData: PersonaData
		)
	}

	@Dependency(\.continuousClock) var clock
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				try await clock.sleep(for: .seconds(0.5))
				await send(.internal(.focusTextField(.personaName)))
			}

		case let .confirmNameButtonTapped(sanitizedName):
			state.focusedInputField = nil
			return .run { [personaData = state.personaData] send in
				await send(.delegate(.proceed(
					personaName: sanitizedName,
					personaData: personaData
				)))
			}

		case let .textFieldFocused(focus):
			return .run { send in
				try await clock.sleep(for: .seconds(0.5))
				await send(.internal(.focusTextField(focus)))
			}

		case let .textFieldChanged(inputtedName):
			state.inputtedName = inputtedName
			state.sanitizedName = NonEmpty(rawValue: state.inputtedName.trimmingWhitespace())
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .focusTextField(focus):
			state.focusedInputField = focus
			return .none
		}
	}
}
