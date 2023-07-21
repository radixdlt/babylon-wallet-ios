import FeaturePrelude

// MARK: - EditPersonaEntries
public struct EditPersonaEntries: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		// FIXME: Find a way to have an array of EditPersonaEntries, instead of separate properties
		var name: EditPersonaEntry<EditPersonaName>.State?
		var emailAddress: EditPersonaEntry<EditPersonaDynamicField>.State?
		var phoneNumber: EditPersonaEntry<EditPersonaDynamicField>.State?

		init(with personaData: PersonaData, mode: EditPersona.State.Mode) {
			let required = mode.requiredEntries

			self.name = (personaData.name?.value).map {
				.entry(name: $0, isRequestedByDapp: required.contains(.fullName))
			}
			self.emailAddress = (personaData.emailAddresses.first).flatMap {
				try? .singleFieldEntry(.emailAddress, text: $0.value.email, isRequestedByDapp: required.contains(.emailAddress))
			}
			self.phoneNumber = (personaData.phoneNumbers.first).flatMap {
				try? .singleFieldEntry(.phoneNumber, text: $0.value.number, isRequestedByDapp: required.contains(.phoneNumber))
			}

			for kind in required {
				switch kind {
				case .fullName where self.name == nil:
					self.name = .entry(isRequestedByDapp: true)

				case .emailAddress where self.emailAddress == nil:
					self.emailAddress = try? .singleFieldEntry(kind, isRequestedByDapp: true)

				case .phoneNumber where self.phoneNumber == nil:
					self.phoneNumber = try? .singleFieldEntry(kind, isRequestedByDapp: true)

				default:
					continue
				}
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case name(EditPersonaEntry<EditPersonaName>.Action)
		case emailAddress(EditPersonaEntry<EditPersonaDynamicField>.Action)
		case phoneNumber(EditPersonaEntry<EditPersonaDynamicField>.Action)
	}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.name, action: /Action.child .. ChildAction.name) {
				EditPersonaEntry<EditPersonaName>()
			}
			.ifLet(\.emailAddress, action: /Action.child .. ChildAction.emailAddress) {
				EditPersonaEntry<EditPersonaDynamicField>()
			}
			.ifLet(\.phoneNumber, action: /Action.child .. ChildAction.phoneNumber) {
				EditPersonaEntry<EditPersonaDynamicField>()
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
