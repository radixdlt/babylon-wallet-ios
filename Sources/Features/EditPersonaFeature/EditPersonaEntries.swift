import FeaturePrelude

// MARK: - EditPersonaEntries
public struct EditPersonaEntries: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		// FIXME: Find a way to have an array of EditPersonaEntries, instead of separate properties
		var name: EditPersonaEntry<EditPersonaName>.State?
		var emailAddress: EditPersonaEntry<EditPersonaDynamicField>.State?
		var phoneNumber: EditPersonaEntry<EditPersonaDynamicField>.State?

		init(with personaData: PersonaData, mode: EditPersona.State.Mode) {
			func isRequestedByDap(_ kind: EntryKind) -> Bool {
				if case let .dapp(requiredEntries) = mode {
					return requiredEntries.contains(kind)
				}
				return false
			}

			self.name = (personaData.name?.value).map {
				let isRequestedByDapp = isRequestedByDap(.fullName)

				return EditPersonaEntry<EditPersonaName>.State(
					kind: .fullName,
					isRequestedByDapp: isRequestedByDapp,
					content: EditPersonaName.State(
						with: $0,
						isRequestedByDapp: isRequestedByDapp
					)
				)
			}
			self.emailAddress = (personaData.emailAddresses.first).map {
				let isRequestedByDapp = isRequestedByDap(.emailAddress)

				return EditPersonaEntry<EditPersonaDynamicField>.State(
					kind: .emailAddress,
					isRequestedByDapp: isRequestedByDapp,
					content: .init(
						id: .emailAddress,
						text: $0.value.email,
						isRequiredByDapp: isRequestedByDapp,
						showsName: false
					)
				)
			}
			self.phoneNumber = (personaData.phoneNumbers.first).map {
				let isRequestedByDapp = isRequestedByDap(.phoneNumber)

				return EditPersonaEntry<EditPersonaDynamicField>.State(
					kind: .phoneNumber,
					isRequestedByDapp: isRequestedByDapp,
					content: .init(
						id: .phoneNumber,
						text: $0.value.number,
						isRequiredByDapp: isRequestedByDapp,
						showsName: false
					)
				)
			}

			if case let .dapp(requiredEntries) = mode {
				requiredEntries.forEach { kind in
					switch kind {
					case .fullName where self.name == nil:
						self.name = .init(
							kind: .fullName,
							isRequestedByDapp: true,
							content: .init(
								with: .init(variant: .eastern, familyName: "", givenNames: ""),
								isRequestedByDapp: true
							)
						)
					case .emailAddress where self.emailAddress == nil:
						self.emailAddress = .init(
							kind: .emailAddress,
							isRequestedByDapp: true,
							content: .init(
								id: .emailAddress,
								text: "",
								isRequiredByDapp: true,
								showsName: false
							)
						)
					case .phoneNumber where self.phoneNumber == nil:
						self.phoneNumber = .init(
							kind: .phoneNumber,
							isRequestedByDapp: true,
							content: .init(
								id: .phoneNumber,
								text: "",
								isRequiredByDapp: true, showsName: false
							)
						)
					default:
						break
					}
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
				EditPersonaEntry<EditPersonaDynamicField>()
			}
			.ifLet(
				\.phoneNumber,
				action: /Action.child .. ChildAction.phoneNumber
			) {
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
