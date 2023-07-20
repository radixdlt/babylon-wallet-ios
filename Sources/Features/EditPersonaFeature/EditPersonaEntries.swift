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
