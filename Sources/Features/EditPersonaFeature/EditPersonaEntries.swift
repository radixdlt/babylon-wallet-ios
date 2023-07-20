import FeaturePrelude

// MARK: - EditPersonaEntries
public struct EditPersonaEntries: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var name: EditPersonaEntry<EditPersonaName>.State?
		var emailAddress: EditPersonaDynamicField.State?
		var phoneNumber: EditPersonaDynamicField.State?

		init(with personaData: PersonaData) {
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
			self.emailAddress = (personaData.emailAddresses.first).map {
				.init(
					id: .emailAddress,
					text: $0.value.email,
					isRequiredByDapp: false
				)
			}
			self.phoneNumber = (personaData.phoneNumbers.first).map {
				.init(
					id: .phoneNumber,
					text: $0.value.number,
					isRequiredByDapp: false
				)
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case name(EditPersonaEntry<EditPersonaName>.Action)
		case emailAddress(EditPersonaDynamicField.Action)
		case phoneNumber(EditPersonaDynamicField.Action)
	}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(
				\.name,
				action: /Action.child .. ChildAction.name
			) {
				EditPersonaEntry<EditPersonaName>()
			}
			.ifLet(
				\.emailAddress,
				action: /Action.child .. ChildAction.emailAddress
			) {
				EditPersonaField()
			}
			.ifLet(
				\.phoneNumber,
				action: /Action.child .. ChildAction.phoneNumber
			) {
				EditPersonaField()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .name(.delegate(.delete)):
			state.name = nil
			return .none

		case .emailAddress(.delegate(.delete)):
			state.emailAddress = nil
			return .none

		case .phoneNumber(.delegate(.delete)):
			state.phoneNumber = nil
			return .none

		default:
			return .none
		}
	}
}
