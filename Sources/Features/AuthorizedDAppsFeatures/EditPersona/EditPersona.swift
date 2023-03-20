import FeaturePrelude

// MARK: - EditPersonaDetails
public struct EditPersona: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Focus: Sendable, Hashable {
			case personaLabel
			case givenName
			case familyName
			case emailAddress
			case phoneNumber
		}

		var focus: Focus?

		@Validation<String, String>
		var personaLabel: String?
		@Validation<String, String>
		var givenName: String?
		@Validation<String, String>
		var familyName: String?

		public init(
			personaLabel: NonEmptyString,
			existingFields: IdentifiedArrayOf<Profile.Network.Persona.Field>,
			fieldsRequiredByDapp: [Profile.Network.Persona.Field.Kind] = [],
			initialFocus: Focus? = nil
		) {
			self.focus = initialFocus
			self._personaLabel = .init(
				wrappedValue: personaLabel.rawValue,
				onNil: L10n.EditPersona.InputError.PersonaLabel.blank,
				rules: [.if(\.isBlank, error: L10n.EditPersona.InputError.PersonaLabel.blank)]
			)
			let isGivenNameRequiredByDapp = fieldsRequiredByDapp.contains(.givenName)
			self._givenName = .init(
				wrappedValue: existingFields.first(where: { $0.kind == .givenName })?.value.rawValue,
				onNil: isGivenNameRequiredByDapp ? L10n.EditPersona.InputError.All.requiredByDapp : nil,
				rules: [.if(\.isBlank, error: L10n.EditPersona.InputError.All.requiredByDapp)],
				exceptions: isGivenNameRequiredByDapp ? [] : [\.isEmpty]
			)
			let isFamilyNameRequiredByDapp = fieldsRequiredByDapp.contains(.familyName)
			self._familyName = .init(
				wrappedValue: existingFields.first(where: { $0.kind == .familyName })?.value.rawValue,
				onNil: isFamilyNameRequiredByDapp ? L10n.EditPersona.InputError.All.requiredByDapp : nil,
				rules: [.if(\.isBlank, error: L10n.EditPersona.InputError.All.requiredByDapp)],
				exceptions: isFamilyNameRequiredByDapp ? [] : [\.isEmpty]
			)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case focusChanged(State.Focus?)
		case personaLabelTextFieldChanged(String)
		case givenNameTextFieldChanged(String)
		case familyNameTextFieldChanged(String)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .focusChanged(focus):
			state.focus = focus
			return .none

		case let .personaLabelTextFieldChanged(personaLabel):
			state.personaLabel = personaLabel
			return .none

		case let .givenNameTextFieldChanged(givenName):
			state.givenName = givenName
			return .none

		case let .familyNameTextFieldChanged(familyName):
			state.familyName = familyName
			return .none
		}
	}
}
