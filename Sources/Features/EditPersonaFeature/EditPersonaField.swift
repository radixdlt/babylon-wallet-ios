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
public struct EditPersonaField<ID: EditPersonaFieldID>: Sendable, FeatureReducer, EmptyInitializable {
	public struct State: Sendable, Hashable, Identifiable {
		public let id: ID
		let isRequestedByDapp: Bool
		let showsName: Bool

		@Validation<String, String>
		public var input: String?

		private init(
			id: ID,
			input: Validation<String, String>,
			isRequestedByDapp: Bool,
			showsName: Bool
		) {
			self.id = id
			self._input = input
			self.isRequestedByDapp = isRequestedByDapp
			self.showsName = showsName
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
			id: id,
			input: .init(
				wrappedValue: initial,
				onNil: L10n.EditPersona.Error.blank,
				rules: [.if(\.isBlank, error: L10n.EditPersona.Error.blank)]
			),
			isRequestedByDapp: false,
			showsName: true
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

// MARK: EditPersonaFieldID
extension DynamicFieldID: EditPersonaFieldID {
	// FIXME: Localize
	public var title: String {
		switch self {
		case .givenNames: return "Given names(s)"
		case .nickName: return "Nickname"
		case .familyName: return "Family Name"
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

extension EditPersonaDynamicField.State {
	public init(
		id: ID,
		text: String?,
		isRequiredByDapp: Bool,
		showsName: Bool
	) {
		self.init(
			id: id,
			input: .init(
				wrappedValue: text,
				onNil: nil,
				rules: []
			),
			isRequestedByDapp: isRequiredByDapp,
			showsName: showsName
		)
	}
}
