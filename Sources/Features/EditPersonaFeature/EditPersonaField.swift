import FeaturePrelude
import Profile

public struct EditPersonaField: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public let id: EditPersona.State.Field

		@Validation<String, String>
		public var input: String?

		public let isRequiredByDapp: Bool

		public static func label(
			initial: String?
		) -> Self {
			.init(
				id: .personaLabel,
				input: .init(
					wrappedValue: initial,
					onNil: L10n.EditPersona.InputError.PersonaLabel.blank,
					rules: [.if(\.isBlank, error: L10n.EditPersona.InputError.PersonaLabel.blank)]
				),
				isRequiredByDapp: false
			)
		}

		public static func other(
			_ id: EditPersona.State.Field,
			initial: String?,
			isRequiredByDapp: Bool
		) -> Self {
			.init(
				id: id,
				input: .init(
					wrappedValue: initial,
					onNil: nil, // TODO:
					rules: []
				),
				isRequiredByDapp: isRequiredByDapp
			)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case inputFieldChanged(String)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .inputFieldChanged(input):
			state.input = input
			return .none
		}
	}
}
