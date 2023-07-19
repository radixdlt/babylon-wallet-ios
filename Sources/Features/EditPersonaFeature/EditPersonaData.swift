import FeaturePrelude

// MARK: - EditPersonaData
public struct EditPersonaData: Sendable, FeatureReducer {
	public typealias State = EditPersonaDynamicEntry.State?

	public enum ChildAction: Sendable, Equatable {
		case emailAddress(EditPersonaDynamicEntry.Action)
	}

	public var body: some ReducerProtocolOf<Self> {
		EmptyReducer()
			.ifLet(
				\.self,
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
