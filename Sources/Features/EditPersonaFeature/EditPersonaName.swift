import FeaturePrelude

// MARK: - EditPersonaName
public struct EditPersonaName: FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Property: Sendable, Hashable {
			case family
			case given
		}

		var family: EditPersonaField<Property>.State
		var given: EditPersonaField<Property>.State

		init(
			with name: PersonaData.Name,
			isRequestedByDapp: Bool
		) {
			self.family = EditPersonaField<State.Property>.State(
				id: .family,
				text: name.family,
				isRequiredByDapp: false
			)
			self.given = EditPersonaField<State.Property>.State(
				id: .given,
				text: name.given,
				isRequiredByDapp: false
			)
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case family(EditPersonaField<State.Property>.Action)
		case given(EditPersonaField<State.Property>.Action)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(
			state: \.family,
			action: /Action.child .. ChildAction.family,
			child: EditPersonaField.init
		)
		Scope(
			state: \.given,
			action: /Action.child .. ChildAction.given,
			child: EditPersonaField.init
		)
	}
}

// MARK: - EditPersonaName.State.Property + EditPersonaFieldID
extension EditPersonaName.State.Property: EditPersonaFieldID {
	public var title: String { "name" }
	public var contentType: UITextContentType? { .name }
	public var keyboardType: UIKeyboardType { .default }
	public var capitalization: DesignSystem.EquatableTextInputCapitalization? { .words }
}

// MARK: - EditPersonaName + EmptyInitializable
extension EditPersonaName: EmptyInitializable {}
