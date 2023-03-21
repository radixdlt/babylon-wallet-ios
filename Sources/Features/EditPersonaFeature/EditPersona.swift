import FeaturePrelude
import Profile

// MARK: - EditPersonaDetails
public struct EditPersona: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case edit
			case dapp(requiredFields: [DynamicField])
		}

		public enum StaticField: Sendable, Hashable {
			case personaLabel
		}

		public typealias DynamicField = Profile.Network.Persona.Field.Kind

		var labelField: EditPersonaStaticField.State
		var dynamicFields: IdentifiedArrayOf<EditPersonaDynamicField.State>

		public init(
			mode: Mode,
			personaLabel: NonEmptyString,
			existingFields: IdentifiedArrayOf<Profile.Network.Persona.Field>
		) {
			self.labelField = EditPersonaStaticField.State(initial: personaLabel.rawValue)
			self.dynamicFields = IdentifiedArray(
				uncheckedUniqueElements: existingFields.map { field in
					EditPersonaDynamicField.State(
						field.kind,
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
		case labelField(EditPersonaStaticField.Action)
		case dynamicField(id: EditPersonaDynamicField.State.ID, action: EditPersonaDynamicField.Action)
	}

	public init() {}

	@Dependency(\.dismiss) var dismiss

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.labelField, action: /Action.child .. ChildAction.labelField) {
			EditPersonaField()
		}

		Reduce(core)
			.forEach(\.dynamicFields, action: /Action.child .. ChildAction.dynamicField) {
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
