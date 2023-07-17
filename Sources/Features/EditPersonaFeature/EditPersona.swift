import FeaturePrelude
import PersonasClient

// MARK: - EditPersona.Output
extension EditPersona {
	public struct Output: Sendable, Hashable {
		let personaLabel: NonEmptyString
		let fields: IdentifiedArrayOf<Identified<EditPersonaDynamicField.State.ID, String>>
	}
}

// MARK: - EditPersona
public struct EditPersona: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case edit
//			case dapp(requiredFieldIDs: Set<DynamicFieldID>)
		}

		public enum StaticFieldID: Sendable, Hashable, Comparable {
			case personaLabel
		}

		public typealias DynamicFieldID = PersonaData.Entry

		let mode: Mode
		let persona: Profile.Network.Persona
		var labelField: EditPersonaStaticField.State
		@Sorted(by: \.id)
		var dynamicFields: IdentifiedArrayOf<EditPersonaDynamicField.State> = []

		@PresentationState
		var destination: Destinations.State? = nil

		public init(
			mode: Mode,
			persona: Profile.Network.Persona
		) {
			self.mode = mode
			self.persona = persona
			self.labelField = EditPersonaStaticField.State(
				id: .personaLabel,
				initial: persona.displayName.rawValue
			)
			self.dynamicFields = persona.personaData.dynamicFields(in: mode)
//			if case let .dapp(requiredFieldIDs) = mode {
//				for requiredFieldID in requiredFieldIDs where dynamicFields[id: requiredFieldID] == nil {
//					dynamicFields.append(.init(id: requiredFieldID, initial: nil, isRequiredByDapp: true))
//				}
//			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case saveButtonTapped(Output)
		case addAFieldButtonTapped

		public enum CloseConfirmationDialogAction: Sendable, Hashable {
			case discardChanges
			case keepEditing
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case labelField(EditPersonaStaticField.Action)
		case dynamicField(id: EditPersonaDynamicField.State.ID, action: EditPersonaDynamicField.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case personaSaved(Profile.Network.Persona)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
//			case closeConfirmationDialog(ConfirmationDialogState<ViewAction.CloseConfirmationDialogAction>)
			case addFields(EditPersonaAddEntryKinds.State)
		}

		public enum Action: Sendable, Equatable {
//			case closeConfirmationDialog(ViewAction.CloseConfirmationDialogAction)
			case addFields(EditPersonaAddEntryKinds.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.addFields, action: /Action.addFields) {
				EditPersonaAddEntryKinds()
			}
		}
	}

	public init() {}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.errorQueue) var errorQueue

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.labelField, action: /Action.child .. ChildAction.labelField) {
			EditPersonaField()
		}

		Reduce(core)
			.forEach(\.dynamicFields, action: /Action.child .. ChildAction.dynamicField) {
				EditPersonaField()
			}
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			guard state.hasChanges() else {
				return .fireAndForget {
					await dismiss()
				}
			}

//			state.destination = .closeConfirmationDialog(
//				.init(titleVisibility: .hidden) {
//					TextState("")
//				} actions: {
//					ButtonState(role: .destructive, action: .send(.discardChanges)) {
//						TextState(L10n.EditPersona.CloseConfirmationDialog.discardChanges)
//					}
//					ButtonState(role: .cancel, action: .send(.keepEditing)) {
//						TextState(L10n.EditPersona.CloseConfirmationDialog.keepEditing)
//					}
//				} message: {
//					TextState(L10n.EditPersona.CloseConfirmationDialog.message)
//				}
//			)

			return .none

		case let .saveButtonTapped(output):
			return .run { [state] send in
				let updatedPersona = state.persona.updated(with: output)
				try await personasClient.updatePersona(updatedPersona)
				await send(.delegate(.personaSaved(updatedPersona)))
				await dismiss()
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .addAFieldButtonTapped:
			state.destination = .addFields(.init(excludedEntryKinds: state.dynamicFields.map(\.id.kind)))
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.addFields(.delegate(.addEntryKinds(fieldsToAdd))))):
			state.dynamicFields.append(contentsOf: fieldsToAdd.map {
				.init(
					id: $0.entry,
					text: nil,
					isRequiredByDapp: false
				)
			})
			state.destination = nil
			return .none

		case let .dynamicField(id, action: .delegate(.delete)):
			state.dynamicFields.remove(id: id)
			return .none

		default:
			return .none
		}
	}

//	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
//		switch childAction {
//		case .destination(.presented(.closeConfirmationDialog(.discardChanges))):
//			return .fireAndForget { await dismiss() }
//
//		case let .destination(.presented(.addEntryKinds(.delegate(.addEntryKinds(fieldsToAdd))))):
//			state.dynamicFields.append(contentsOf: fieldsToAdd.map { .init(id: $0, initial: nil, isRequiredByDapp: false) })
//			state.destination = nil
//			return .none
//
//		case let .dynamicField(id, action: .delegate(.delete)):
//			state.dynamicFields.remove(id: id)
//			return .none
//
//		default:
//			return .none
//		}
//	}
}

extension EditPersona.State {
	func hasChanges() -> Bool {
		guard let output = viewState.output else { return false }
		return output.personaLabel != persona.displayName
			|| fieldsOutput(dynamicFields: persona.personaData.dynamicFields(in: mode)) != output.fields
	}
}

extension PersonaData {
	func dynamicFields(
		in mode: EditPersona.State.Mode
	) -> IdentifiedArrayOf<EditPersonaDynamicField.State> {
		IdentifiedArray(
			uncheckedUniqueElements: entries.map { entry in
				EditPersonaDynamicField.State(
					id: entry.value,
					text: entry.value.text,
					isRequiredByDapp: {
						switch mode {
						case .edit:
							return false
						}
					}()
				)
			}
		)
	}
}

extension Profile.Network.Persona {
	fileprivate func updated(with output: EditPersona.Output) -> Self {
		var updatedPersona = self

		updatedPersona.displayName = output.personaLabel

		updatedPersona.personaData = .init()
		output.fields.forEach { identifiedFieldOutput in
			// FIXME: Implement when multi-field entries support will be implemented in the UI, or entries will become supported at all
			switch identifiedFieldOutput.id {
			case .name: break
			case .dateOfBirth: break
			case .companyName: break
			case .emailAddress:
				updatedPersona.personaData.emailAddresses = (try? .init(
					collection: .init(
						uncheckedUniqueElements: [
							.init(value: .init(email: identifiedFieldOutput.value)),
						]
					)
				)) ?? .init()
			case .phoneNumber:
				updatedPersona.personaData.phoneNumbers = (try? .init(
					collection: .init(
						uncheckedUniqueElements: [
							.init(value: .init(number: identifiedFieldOutput.value)),
						]
					)
				)) ?? .init()
			case .url: break
			case .postalAddress: break
			case .creditCard: break
			}
		}

		return updatedPersona
	}
}

extension PersonaData.Entry {
	// FIXME: Use proper values and granularity (Entry-, instead of Field-level) when Entry types will be supported
	var text: String {
		switch self {
		case let .name(entryModel): return entryModel.description
		case let .emailAddress(entryModel): return entryModel.email
		case let .phoneNumber(entryModel): return entryModel.number
		default: fatalError()
		}
	}
}

extension PersonaData.Entry.Kind {
	var entry: PersonaData.Entry {
		switch self {
		case .name:
			return .name(.init(given: "", family: "", variant: .eastern))
		case .dateOfBirth:
			fallthrough
		case .companyName:
			fatalError()
		case .emailAddress:
			return .emailAddress(.init(email: ""))
		case .url:
			fatalError()
		case .phoneNumber:
			return .phoneNumber(.init(number: ""))
		case .postalAddress:
			fatalError()
		case .creditCard:
			fatalError()
		}
	}
}

extension PersonaData.Entry {
	var kind: Kind {
		switch self {
		case .name: return .name
		case .dateOfBirth: return .dateOfBirth
		case .companyName: return .companyName
		case .emailAddress: return .emailAddress
		case .phoneNumber: return .phoneNumber
		case .url: return .url
		case .postalAddress: return .postalAddress
		case .creditCard: return .creditCard
		}
	}
}
