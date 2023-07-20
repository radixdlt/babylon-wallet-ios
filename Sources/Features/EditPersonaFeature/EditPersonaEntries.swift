import FeaturePrelude

// MARK: - EditPersonaEntries
public struct EditPersonaEntries: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var name: EditPersonaName.State?
		var emailAddress: EditPersonaDynamicField.State?

		init(with personaData: PersonaData) {
			self.emailAddress = (personaData.emailAddresses.first).map {
				.init(
					id: .emailAddress,
					text: $0.value.email,
					isRequiredByDapp: false
				)
			}
			self.name = (personaData.name?.value).map(EditPersonaName.State.init)
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case emailAddress(EditPersonaDynamicField.Action)
		case name(EditPersonaName.Action)
	}

	public var body: some ReducerProtocolOf<Self> {
		EmptyReducer()
			.ifLet(
				\.emailAddress,
				action: /Action.child .. ChildAction.emailAddress
			) {
				EditPersonaField()
			}
			.ifLet(
				\.name,
				action: /Action.child .. ChildAction.name
			) {
				EditPersonaName()
			}
	}
}

// MARK: - EditPersonaName
public struct EditPersonaName: FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Property: Sendable, Hashable {
			case family
			case given
		}

		var family: EditPersonaField<Property>.State
		var given: EditPersonaField<Property>.State

		init(with name: PersonaData.Name) {
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

// MARK: - EditPersonaName.View
extension EditPersonaName {
	public struct View: SwiftUI.View {
		let store: StoreOf<EditPersonaName>

		public var body: some SwiftUI.View {
			HStack {
				EditPersonaField.View(
					store: store.scope(
						state: \.family,
						action: (/Action.child
							.. EditPersonaName.ChildAction.family
						).embed
					)
				)
				EditPersonaField.View(
					store: store.scope(
						state: \.given,
						action: (/Action.child
							.. EditPersonaName.ChildAction.given
						).embed
					)
				)
			}
		}
	}
}
