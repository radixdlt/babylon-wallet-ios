import FeaturePrelude

// MARK: - EditPersonaFieldID
public protocol EditPersonaFieldID: Sendable, Hashable, Comparable {
	var title: String { get }
	#if os(iOS)
	var contentType: UITextContentType? { get }
	var keyboardType: UIKeyboardType { get }
	var capitalization: EquatableTextInputCapitalization? { get }
	#endif
}

// MARK: - EditPersonaField
public struct EditPersonaField<ID: EditPersonaFieldID>: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public enum Kind: Sendable, Hashable {
			case `static`
			case dynamic(isRequiredByDapp: Bool)

			var isStatic: Bool {
				self == .static
			}

			var isDynamic: Bool {
				guard case .dynamic = self else { return false }
				return true
			}
		}

		public let kind: Kind
		public let id: ID

		@Validation<String, String>
		public var input: String?

		private init(
			kind: Kind,
			id: ID,
			input: Validation<String, String>
		) {
			self.kind = kind
			self.id = id
			self._input = input
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
		case .personaLabel: return L10n.AuthorizedDapps.PersonaDetails.personaLabelHeading
		}
	}

	#if os(iOS)
	public var contentType: UITextContentType? {
		switch self {
		case .personaLabel: return .none
		}
	}

	public var keyboardType: UIKeyboardType {
		switch self {
		case .personaLabel: return .default
		}
	}

	public var capitalization: EquatableTextInputCapitalization? {
		switch self {
		case .personaLabel: return .words
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
			kind: .static,
			id: id,
			input: .init(
				wrappedValue: initial,
				onNil: L10n.EditPersona.Error.blank,
				rules: [.if(\.isBlank, error: L10n.EditPersona.Error.blank)]
			)
		)
	}
}

// MARK: Dynamic Fields

public typealias EditPersonaDynamicField = EditPersonaField<EditPersona.State.DynamicFieldID>

// MARK: - EditPersona.State.DynamicFieldID + EditPersonaFieldID
extension EditPersona.State.DynamicFieldID: EditPersonaFieldID {
	// FIXME: Localize
	public var title: String {
		switch self {
		case .name: return "Name"
		case .dateOfBirth: return "DoB"
		case .companyName: return "Company name"
		case .emailAddress: return L10n.AuthorizedDapps.PersonaDetails.emailAddress
		case .phoneNumber: return L10n.AuthorizedDapps.PersonaDetails.phoneNumber
		case .url: return "URL"
		case .postalAddress: return "Postal Address"
		case .creditCard: return "Credit Card"
		}
	}

	#if os(iOS)
	public var contentType: UITextContentType? {
		switch self {
		case .name: return .name
		case .dateOfBirth: return .dateTime
		case .companyName: return .organizationName
		case .emailAddress: return .emailAddress
		case .phoneNumber: return .telephoneNumber
		case .url: return .URL
		case .postalAddress: return .fullStreetAddress
		case .creditCard: return .creditCardNumber
		}
	}

	public var keyboardType: UIKeyboardType {
		switch self {
		case .name: return .default
		case .dateOfBirth: return .default
		case .companyName: return .default
		case .emailAddress: return .emailAddress
		case .phoneNumber: return .phonePad
		case .url: return .URL
		case .postalAddress: return .default
		case .creditCard: return .asciiCapableNumberPad
		}
	}

	public var capitalization: EquatableTextInputCapitalization? {
		switch self {
		case .name: return .words
		case .dateOfBirth: return .never
		case .companyName: return .words
		case .emailAddress: return .never
		case .phoneNumber: return .none
		case .url: return .never
		case .postalAddress: return .words
		case .creditCard: return .none
		}
	}
	#endif
}

// MARK: - EditPersona.State.DynamicFieldID + Comparable
extension EditPersona.State.DynamicFieldID: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		guard
			let lhsIndex = Self.supportedKinds.firstIndex(of: lhs),
			let rhsIndex = Self.supportedKinds.firstIndex(of: rhs)
		else {
			assertionFailure(
				"""
				This code path should never occur, unless you're manually conforming to `CaseIterable` and `allCases` is incomplete.
				"""
			)
			return false
		}
		return lhsIndex < rhsIndex
	}
}

extension EditPersona.State.DynamicFieldID {
	static var supportedKinds: [Self] {
		[
			.name,
			.emailAddress,
			.phoneNumber,
		]
	}
}

extension EditPersonaDynamicField.State {
	public init(
		id: ID,
		text: String?,
		isRequiredByDapp: Bool
	) {
		self.init(
			kind: .dynamic(isRequiredByDapp: isRequiredByDapp),
			id: id,
			input: .init(
				wrappedValue: text,
				onNil: {
					if isRequiredByDapp {
						return L10n.EditPersona.Error.requiredByDapp
					} else {
						return nil
					}
				}(),
				rules: .build {
					if isRequiredByDapp {
						.if(\.isBlank, error: L10n.EditPersona.Error.requiredByDapp)
					}
					if case PersonaData.Entry.Kind.emailAddress = id {
						.unless(\.isEmailAddress, error: L10n.EditPersona.Error.invalidEmailAddress)
					}
				}
			)
		)
	}
}
