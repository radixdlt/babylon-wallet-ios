import FeaturePrelude

// MARK: - EditPersonaFieldID
public protocol EditPersonaFieldID: Sendable, Hashable, Comparable {
	var title: String { get }
	#if os(iOS)
	var capitalization: EquatableTextInputCapitalization { get }
	var keyboardType: UIKeyboardType { get }
	#endif
}

// MARK: - EditPersonaField
public struct EditPersonaField<ID: EditPersonaFieldID>: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public enum Kind: Sendable, Hashable {
			case `static`
			case dynamic(isRequiredByDapp: Bool)

			var isStatic: Bool {
				guard case .static = self else { return false }
				return true
			}

			var isDynamic: Bool {
				guard case .dynamic = self else { return false }
				return true
			}
		}

		public let id: ID

		@Validation<String, String>
		public var input: String?

		public let kind: Kind

		private init(
			id: ID,
			input: Validation<String, String>,
			kind: Kind
		) {
			self.id = id
			self._input = input
			self.kind = kind
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case inputFieldChanged(String)
		case deleteButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case delete
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .inputFieldChanged(input):
			state.input = input
			return .none

		case .deleteButtonTapped:
			return .send(.delegate(.delete))
		}
	}
}

// MARK: Static Fields

public typealias EditPersonaStaticField = EditPersonaField<EditPersona.State.StaticFieldID>

// MARK: - EditPersona.State.StaticFieldID + EditPersonaFieldID
extension EditPersona.State.StaticFieldID: EditPersonaFieldID {
	public var title: String {
		switch self {
		case .personaLabel: return L10n.PersonaDetails.personaLabelHeading
		}
	}

	#if os(iOS)
	public var capitalization: EquatableTextInputCapitalization {
		switch self {
		case .personaLabel: return .words
		}
	}

	public var keyboardType: UIKeyboardType {
		switch self {
		case .personaLabel: return .default
		}
	}
	#endif
}

extension EditPersonaStaticField.State {
	public init(
		id: ID,
		initial: String?
	) {
		self.init(
			id: id,
			input: .init(
				wrappedValue: initial,
				onNil: L10n.EditPersona.InputField.Error.PersonaLabel.blank,
				rules: [.if(\.isBlank, error: L10n.EditPersona.InputField.Error.PersonaLabel.blank)]
			),
			kind: .static
		)
	}
}

// MARK: Dynamic Fields

public typealias EditPersonaDynamicField = EditPersonaField<EditPersona.State.DynamicFieldID>

// MARK: - EditPersona.State.DynamicFieldID + EditPersonaFieldID
extension EditPersona.State.DynamicFieldID: EditPersonaFieldID {
	public var title: String {
		switch self {
		case .givenName: return L10n.PersonaDetails.givenNameHeading
		case .familyName: return L10n.PersonaDetails.familyNameHeading
		case .emailAddress: return L10n.PersonaDetails.emailAddressHeading
		case .phoneNumber: return L10n.PersonaDetails.phoneNumberHeading
		}
	}

	#if os(iOS)
	public var capitalization: EquatableTextInputCapitalization {
		switch self {
		case .givenName: return .words
		case .familyName: return .words
		case .emailAddress: return .never
		case .phoneNumber: return .never
		}
	}

	public var keyboardType: UIKeyboardType {
		switch self {
		case .givenName: return .namePhonePad
		case .familyName: return .namePhonePad
		case .emailAddress: return .emailAddress
		case .phoneNumber: return .phonePad
		}
	}
	#endif
}

extension EditPersonaDynamicField.State {
	public init(
		id: ID,
		initial: String?,
		isRequiredByDapp: Bool
	) {
		self.init(
			id: id,
			input: {
				if isRequiredByDapp {
					return .init(
						wrappedValue: initial,
						onNil: L10n.EditPersona.InputField.Error.General.requiredByDapp,
						rules: [.if(\.isBlank, error: L10n.EditPersona.InputField.Error.General.requiredByDapp)]
					)
				} else {
					return .init(
						wrappedValue: initial,
						onNil: nil,
						rules: []
					)
				}
			}(),
			kind: .dynamic(isRequiredByDapp: isRequiredByDapp)
		)
	}
}
