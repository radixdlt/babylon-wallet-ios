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
		public let id: ID
		private init(
			id: ID // ,
		) {
			self.id = id
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
			id: id // ,
		)
	}
}
