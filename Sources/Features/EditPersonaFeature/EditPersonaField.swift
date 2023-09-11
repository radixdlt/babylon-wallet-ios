import FeaturePrelude

// MARK: - EditPersonaFieldKindBehaviour
public protocol EditPersonaFieldKindBehaviour: Sendable, Hashable, Comparable {
	var title: String { get }
	#if os(iOS)
	var contentType: UITextContentType? { get }
	var keyboardType: UIKeyboardType { get }
	var capitalization: EquatableTextInputCapitalization? { get }
	#endif
}

// MARK: - EditPersonaField
public struct EditPersonaField<Behaviour: EditPersonaFieldKindBehaviour>: Sendable, FeatureReducer, EmptyInitializable {
	public struct State: Sendable, Hashable {
		public let behaviour: Behaviour
		public let entryID: PersonaDataEntryID
		let isRequestedByDapp: Bool
		let showsTitle: Bool

		@Validation<String, String>
		public var input: String?

		private init(
			behaviour: Behaviour,
			entryID: PersonaDataEntryID?,
			input: Validation<String, String>,
			isRequestedByDapp: Bool,
			showsTitle: Bool
		) {
			@Dependency(\.uuid) var uuid
			self.entryID = entryID ?? uuid()
			self.behaviour = behaviour
			self._input = input
			self.isRequestedByDapp = isRequestedByDapp
			self.showsTitle = showsTitle
		}
	}

	public init() {}

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

// MARK: Static Fields

public typealias EditPersonaStaticField = EditPersonaField<EditPersona.State.StaticFieldID>

// MARK: - EditPersona.State.StaticFieldID + EditPersonaFieldKindBehaviour
extension EditPersona.State.StaticFieldID: EditPersonaFieldKindBehaviour {
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
		behaviour: Behaviour,
		entryID: PersonaDataEntryID?,
		initial: String?
	) {
		self.init(
			behaviour: behaviour,
			entryID: entryID,
			input: .init(
				wrappedValue: initial,
				onNil: L10n.EditPersona.Error.blank,
				rules: [.if(\.isBlank, error: L10n.EditPersona.Error.blank)]
			),
			isRequestedByDapp: false,
			showsTitle: true
		)
	}
}

// MARK: Dynamic Fields

public typealias EditPersonaDynamicField = EditPersonaField<DynamicFieldID>

// MARK: - DynamicFieldID
public enum DynamicFieldID: Hashable, Sendable {
	case givenNames
	case nickName
	case familyName
	case emailAddress
	case phoneNumber
	case dateOfBirth
	case companyName
	case url
	case postalAddress
	case creditCard
}

// MARK: EditPersonaFieldKindBehaviour
extension DynamicFieldID: EditPersonaFieldKindBehaviour {
	// FIXME: Localize
	public var title: String {
		switch self {
		case .givenNames: return L10n.AuthorizedDapps.PersonaDetails.givenName
		case .nickName: return L10n.AuthorizedDapps.PersonaDetails.nickname
		case .familyName: return L10n.AuthorizedDapps.PersonaDetails.nameFamily
		case .dateOfBirth: return "DoB"
		case .companyName: return "Company Name"
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
		case .givenNames: return .name
		case .nickName: return .name
		case .familyName: return .name
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
		case .givenNames: return .default
		case .nickName: return .default
		case .familyName: return .default
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
		case .givenNames: return .words
		case .nickName: return .words
		case .familyName: return .words
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

// MARK: - PersonaData.Entry.Kind + Comparable
extension PersonaData.Entry.Kind: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		guard
			let lhsIndex = supportedKinds.firstIndex(of: lhs),
			let rhsIndex = supportedKinds.firstIndex(of: rhs)
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

extension EditPersonaDynamicField.State {
	public init(
		behaviour: Behaviour,
		entryID: PersonaDataEntryID?,
		text: String?,
		isRequiredByDapp: Bool,
		showsTitle: Bool
	) {
		self.init(
			behaviour: behaviour,
			entryID: entryID,
			input: .init(
				wrappedValue: text,
				onNil: nil,
				rules: []
			),
			isRequestedByDapp: isRequiredByDapp,
			showsTitle: showsTitle
		)
	}
}
