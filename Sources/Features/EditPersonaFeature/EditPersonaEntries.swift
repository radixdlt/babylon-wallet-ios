import FeaturePrelude

// MARK: - EditPersonaEntries
public struct EditPersonaEntries: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var emailAddress: EditPersonaDynamicEntry.State?

		init(with personaData: PersonaData) {
			self.emailAddress = (personaData.emailAddresses.first).map {
				.init(
					id: .emailAddress,
					text: $0.value.email,
					isRequiredByDapp: false
				)
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case emailAddress(EditPersonaDynamicEntry.Action)
	}

	public var body: some ReducerProtocolOf<Self> {
		EmptyReducer()
			.ifLet(
				\.emailAddress,
				action: /Action.child .. ChildAction.emailAddress
			) {
				EditPersonaField()
			}
	}
}

extension PersonaData {
	var emailDynamicField: EditPersonaDynamicEntry.State? {
		emailAddresses.first.map {
			.init(
				id: .emailAddress,
				text: $0.value.email,
				isRequiredByDapp: false
			)
		}
	}
}
