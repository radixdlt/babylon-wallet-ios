import FeaturePrelude
import Profile

// MARK: - EditPersonaDetails
public struct EditPersona: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Field: Sendable, Hashable {
			case personaLabel

			case givenName
			case familyName
			case emailAddress
			case phoneNumber

			public init(_ field: Profile.Network.Persona.Field.Kind) {
				switch field {
				case .givenName: self = .givenName
				case .familyName: self = .familyName
				case .emailAddress: self = .emailAddress
				case .phoneNumber: self = .phoneNumber
				}
			}
		}

//		@Validation<String, String>
//		var personaLabel: String?
//		@Validation<String, String>
//		var givenName: String?
//		@Validation<String, String>
//		var familyName: String?

		//            personaLabel: $personaLabel,
		//            personaLabelHint: ($personaLabel.errors?.first).map { .error($0) },
		//            givenName: $givenName,
		//            givenNameHint: ($givenName.errors?.first).map { .error($0) },
		//            familyName: $familyName,
		//            familyNameHint: ($familyName.errors?.first).map { .error($0) }

		var labelField: EditPersonaField.State
		var fields: IdentifiedArrayOf<EditPersonaField.State>

		public init(
			personaLabel: NonEmptyString,
			existingFields: IdentifiedArrayOf<Profile.Network.Persona.Field>,
			fieldsRequiredByDapp: [Profile.Network.Persona.Field.Kind] = []
		) {
			self.labelField = .label(initial: personaLabel.rawValue)
			self.fields = IdentifiedArray(
				uncheckedUniqueElements: existingFields.map { field in
					EditPersonaField.State.other(
						.init(field.kind),
						initial: field.value.rawValue,
						isRequiredByDapp: fieldsRequiredByDapp.contains(field.kind)
					)
				}
			)
//			self._personaLabel = .init(
//				wrappedValue: personaLabel.rawValue,
//				onNil: L10n.EditPersona.InputError.PersonaLabel.blank,
//				rules: [.if(\.isBlank, error: L10n.EditPersona.InputError.PersonaLabel.blank)]
//			)
//			let isGivenNameRequiredByDapp = fieldsRequiredByDapp.contains(.givenName)
//			self._givenName = .init(
//				wrappedValue: existingFields.first(where: { $0.kind == .givenName })?.value.rawValue,
//				onNil: isGivenNameRequiredByDapp ? L10n.EditPersona.InputError.All.requiredByDapp : nil,
//				rules: [.if(\.isBlank, error: L10n.EditPersona.InputError.All.requiredByDapp)],
//				exceptions: isGivenNameRequiredByDapp ? [] : [\.isEmpty]
//			)
//			let isFamilyNameRequiredByDapp = fieldsRequiredByDapp.contains(.familyName)
//			self._familyName = .init(
//				wrappedValue: existingFields.first(where: { $0.kind == .familyName })?.value.rawValue,
//				onNil: isFamilyNameRequiredByDapp ? L10n.EditPersona.InputError.All.requiredByDapp : nil,
//				rules: [.if(\.isBlank, error: L10n.EditPersona.InputError.All.requiredByDapp)],
//				exceptions: isFamilyNameRequiredByDapp ? [] : [\.isEmpty]
//			)
		}
	}

	public enum ViewAction: Sendable, Equatable {
//		case personaLabelTextFieldChanged(String)
//		case givenNameTextFieldChanged(String)
//		case familyNameTextFieldChanged(String)
	}

	public enum ChildAction: Sendable, Equatable {
		case field(id: State.Field, action: EditPersonaField.Action)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
//		case let .personaLabelTextFieldChanged(personaLabel):
//			state.personaLabel = personaLabel
//			return .none
//
//		case let .givenNameTextFieldChanged(givenName):
//			state.givenName = givenName
//			return .none
//
//		case let .familyNameTextFieldChanged(familyName):
//			state.familyName = familyName
//			return .none
		}
	}
}
