import ComposableArchitecture
import SwiftUI

// MARK: - EditPersonaFieldKindBehaviour
public protocol EditPersonaFieldKindBehaviour: Sendable, Hashable, Comparable {
	var title: String { get }
	var contentType: UITextContentType? { get }
	var keyboardType: UIKeyboardType { get }
	var capitalization: EquatableTextInputCapitalization? { get }
}

// MARK: - EditPersonaField
public struct EditPersonaField<Behaviour: EditPersonaFieldKindBehaviour>: Sendable, FeatureReducer, EmptyInitializable {
	public struct State: Sendable, Hashable {
		public let behaviour: Behaviour
		public let entryID: PersonaDataEntryID
		let isRequestedByDapp: Bool
		let showsTitle: Bool
		let defaultInfoHint: String?

		@Validation<String, String>
		public var input: String?

		private init(
			behaviour: Behaviour,
			entryID: PersonaDataEntryID?,
			input: Validation<String, String>,
			isRequestedByDapp: Bool,
			showsTitle: Bool,
			defaultInfoHint: String? = nil
		) {
			@Dependency(\.uuid) var uuid
			self.entryID = entryID ?? uuid()
			self.behaviour = behaviour
			self._input = input
			self.isRequestedByDapp = isRequestedByDapp
			self.showsTitle = showsTitle
			self.defaultInfoHint = defaultInfoHint
		}
	}

	public init() {}

	public enum ViewAction: Sendable, Equatable {
		case inputFieldChanged(String)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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
		case .personaLabel: L10n.AuthorizedDapps.PersonaDetails.personaLabelHeading
		}
	}

	public var contentType: UITextContentType? {
		switch self {
		case .personaLabel: .none
		}
	}

	public var keyboardType: UIKeyboardType {
		switch self {
		case .personaLabel: .default
		}
	}

	public var capitalization: EquatableTextInputCapitalization? {
		switch self {
		case .personaLabel: .words
		}
	}
}

extension EditPersonaStaticField.State {
	public init(
		behaviour: Behaviour,
		entryID: PersonaDataEntryID?,
		initial: String?,
		defaultInfoHint: String? = nil
	) {
		self.init(
			behaviour: behaviour,
			entryID: entryID,
			input: .init(
				wrappedValue: initial,
				onNil: nil,
				rules: [
					.if(\.isBlank, error: L10n.EditPersona.Error.blank),
					.if({ $0.count > Account.nameMaxLength }, error: L10n.Error.PersonaLabel.tooLong), // FIXME: define nameMaxLength for Persona
				]
			),
			isRequestedByDapp: false,
			showsTitle: true,
			defaultInfoHint: defaultInfoHint
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
		case .givenNames: L10n.AuthorizedDapps.PersonaDetails.givenName
		case .nickName: L10n.AuthorizedDapps.PersonaDetails.nickname
		case .familyName: L10n.AuthorizedDapps.PersonaDetails.nameFamily
		case .dateOfBirth: "DoB"
		case .companyName: "Company Name"
		case .emailAddress: L10n.AuthorizedDapps.PersonaDetails.emailAddress
		case .phoneNumber: L10n.AuthorizedDapps.PersonaDetails.phoneNumber
		case .url: "URL"
		case .postalAddress: "Postal Address"
		case .creditCard: "Credit Card"
		}
	}

	public var contentType: UITextContentType? {
		switch self {
		case .givenNames: .name
		case .nickName: .name
		case .familyName: .name
		case .dateOfBirth: .dateTime
		case .companyName: .organizationName
		case .emailAddress: .emailAddress
		case .phoneNumber: .telephoneNumber
		case .url: .URL
		case .postalAddress: .fullStreetAddress
		case .creditCard: .creditCardNumber
		}
	}

	public var keyboardType: UIKeyboardType {
		switch self {
		case .givenNames: .default
		case .nickName: .default
		case .familyName: .default
		case .dateOfBirth: .default
		case .companyName: .default
		case .emailAddress: .emailAddress
		case .phoneNumber: .phonePad
		case .url: .URL
		case .postalAddress: .default
		case .creditCard: .asciiCapableNumberPad
		}
	}

	public var capitalization: EquatableTextInputCapitalization? {
		switch self {
		case .givenNames: .words
		case .nickName: .words
		case .familyName: .words
		case .dateOfBirth: .never
		case .companyName: .words
		case .emailAddress: .never
		case .phoneNumber: .none
		case .url: .never
		case .postalAddress: .words
		case .creditCard: .none
		}
	}
}

extension PersonaData.Entry.Kind {
	public static var supportedKinds: [Self] {
		[
			.fullName,
			.phoneNumber,
			.emailAddress,
		]
	}
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
		showsTitle: Bool,
		defaultInfoHint: String? = nil
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
			showsTitle: showsTitle,
			defaultInfoHint: defaultInfoHint
		)
	}
}
