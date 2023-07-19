import FeaturePrelude

// MARK: - EditPersonaData
public struct EditPersonaData: Sendable, FeatureReducer {
	public typealias State = PersonaData

	public enum ChildAction: Sendable, Equatable {
		case emailAddress(EditPersonaDynamicEntry.Action)
	}

	public var body: some ReducerProtocolOf<Self> {
		EmptyReducer()
			.ifLet(
				\.emailAddresses.dynamicField,
				action: /Action.child .. ChildAction.emailAddress
			) {
				EditPersonaField()
			}
	}
}

extension EditPersonaDynamicEntry.State {
	var email: Self? {
		get {
			self.id == .emailAddress ? self : nil
		}
		set {}
	}
}

extension PersonaData.IdentifiedEmailAddresses {
	var dynamicField: EditPersonaDynamicEntry.State? {
		get {
			first.map {
				.init(
					id: .emailAddress,
					text: $0.value.email,
					isRequiredByDapp: false
				)
			}
		}
		set {}
	}
}
