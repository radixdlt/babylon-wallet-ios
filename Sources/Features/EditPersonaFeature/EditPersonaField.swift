import FeaturePrelude

// MARK: - EditPersonaFieldProtocol
public protocol EditPersonaFieldProtocol: Sendable, Hashable, Comparable {
	var title: String { get }
	#if os(iOS)
	var capitalization: EquatableTextInputCapitalization { get }
	var keyboardType: UIKeyboardType { get }
	#endif
}

// MARK: - EditPersonaField
public struct EditPersonaField<Field: EditPersonaFieldProtocol>: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public enum Mode: Sendable, Hashable {
			case `static`
			case dynamic(isRequiredByDapp: Bool)

			var isDynamic: Bool {
				switch self {
				case .static:
					return false
				case .dynamic:
					return true
				}
			}

			var isRequiredByDapp: Bool {
				switch self {
				case .static: return false
				case let .dynamic(isRequiredByDapp): return isRequiredByDapp
				}
			}

			var canBeDeleted: Bool {
				switch self {
				case .static: return false
				case let .dynamic(isRequiredByDapp): return !isRequiredByDapp
				}
			}
		}

		public var id: Field { kind }
		public let kind: Field

		@Validation<String, String>
		public var input: String?

		public let mode: Mode

		private init(
			kind: Field,
			input: Validation<String, String>,
			mode: Mode
		) {
			self.kind = kind
			self._input = input
			self.mode = mode
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

public typealias EditPersonaStaticField = EditPersonaField<EditPersona.State.StaticField>

// MARK: - EditPersona.State.StaticField + EditPersonaFieldProtocol
extension EditPersona.State.StaticField: EditPersonaFieldProtocol {
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
		kind: Field,
		initial: String?
	) {
		self.init(
			kind: kind,
			input: .init(
				wrappedValue: initial,
				onNil: L10n.EditPersona.InputField.Error.PersonaLabel.blank,
				rules: [.if(\.isBlank, error: L10n.EditPersona.InputField.Error.PersonaLabel.blank)]
			),
			mode: .static
		)
	}
}

// MARK: Dynamic Fields

public typealias EditPersonaDynamicField = EditPersonaField<EditPersona.State.DynamicField>

// MARK: - EditPersona.State.DynamicField + EditPersonaFieldProtocol
extension EditPersona.State.DynamicField: EditPersonaFieldProtocol {
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
		kind: Field,
		initial: String?,
		isRequiredByDapp: Bool
	) {
		self.init(
			kind: kind,
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
			mode: .dynamic(isRequiredByDapp: isRequiredByDapp)
		)
	}
}
