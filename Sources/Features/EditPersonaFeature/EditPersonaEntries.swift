import FeaturePrelude

// MARK: - EditPersonaEntries
public struct EditPersonaEntries: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var name: EditPersonaEntry<EditPersonaName>.State?
		var emailAddress: EditPersonaDynamicField.State?

		init(with personaData: PersonaData) {
			self.emailAddress = (personaData.emailAddresses.first).map {
				.init(
					id: .emailAddress,
					text: $0.value.email,
					isRequiredByDapp: false
				)
			}
			self.name = (personaData.name?.value).map {
				EditPersonaEntry<EditPersonaName>.State(
					name: "Name...",
					isRequestedByDapp: false,
					content: EditPersonaName.State(
						with: $0,
						isRequestedByDapp: false
					)
				)
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case emailAddress(EditPersonaDynamicField.Action)
		case name(EditPersonaEntry<EditPersonaName>.Action)
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
				EditPersonaEntry<EditPersonaName>()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		default:
			return .none
		}
	}
}
