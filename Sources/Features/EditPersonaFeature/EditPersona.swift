import FeaturePrelude
import Profile

// MARK: - EditPersonaDetails
public struct EditPersona: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case edit
			case dapp(requiredFields: [Profile.Network.Persona.Field.Kind])
		}

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

		var labelField: EditPersonaField.State
		var fields: IdentifiedArrayOf<EditPersonaField.State>

		public init(
			mode: Mode,
			personaLabel: NonEmptyString,
			existingFields: IdentifiedArrayOf<Profile.Network.Persona.Field>
		) {
			self.labelField = .label(initial: personaLabel.rawValue)
			self.fields = IdentifiedArray(
				uncheckedUniqueElements: existingFields.map { field in
					EditPersonaField.State.other(
						.init(field.kind),
						initial: field.value.rawValue,
						isRequiredByDapp: {
							switch mode {
							case .edit:
								return false
							case let .dapp(requiredFields):
								return requiredFields.contains(field.kind)
							}
						}()
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
		case cancelButtonTapped
		case saveButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case labelField(EditPersonaField.Action)
		case field(id: State.Field, action: EditPersonaField.Action)
	}

	public init() {}

	@Dependency(\.dismiss) var dismiss

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.labelField, action: /Action.child .. ChildAction.labelField) {
			EditPersonaField()
		}

		Reduce(core)
			.forEach(\.fields, action: /Action.child .. ChildAction.field) {
				EditPersonaField()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .cancelButtonTapped:
			return .run { _ in await dismiss() }
		case .saveButtonTapped:
			// TODO:
			return .none
		}
	}
}
