import FeaturePrelude
import PersonasClient

// MARK: - EditPersona.Output
extension EditPersona {
	public struct Output: Sendable, Hashable {
		let personaLabel: NonEmptyString
		let fields: IdentifiedArrayOf<Identified<EditPersonaDynamicField.State.ID, String>>
	}
}

extension PersonaData.Entry {
	var text: String {
		// FIXME: Use proper values and granularity (Entry-, instead of Field-level) when Entry types will be supported
		switch self {
		case let .name(entryModel): return entryModel.description
		case let .dateOfBirth(entryModel): return entryModel.description
		case let .companyName(entryModel): return entryModel.description
		case let .emailAddress(entryModel): return entryModel.description
		case let .phoneNumber(entryModel): return entryModel.description
		case let .url(entryModel): return entryModel.description
		case let .postalAddress(entryModel): return entryModel.description
		case let .creditCard(entryModel): return entryModel.description
		}
	}
}

// MARK: - EditPersona
public struct EditPersona: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case edit
		}

		public enum StaticFieldID: Sendable, Hashable, Comparable {
			case personaLabel
		}

		public typealias DynamicFieldID = PersonaData.Entry

		let mode: Mode
		let persona: Profile.Network.Persona
		var labelField: EditPersonaStaticField.State
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
			case addFields(EditPersonaAddFields.State)
		}

		public enum Action: Sendable, Equatable {
			case addFields(EditPersonaAddFields.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.addFields, action: /Action.addFields) {
				EditPersonaAddFields()
			}
			EmptyReducer()
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

			return .none

		case let .saveButtonTapped(output):
			return .run { [state] send in
				var persona = state.persona
				persona.displayName = output.personaLabel
				output.fields.forEach { identifiedFieldOutput in
					switch identifiedFieldOutput.id {
					// FIXME: Implement when multi-field entries support will be implemented in the UI, or entries will become supported at all
					case let .name(entryModel): break
					case let .dateOfBirth(entryModel): break
					case let .companyName(entryModel): break
					case let .emailAddress(entryModel):
						persona.personaData.emailAddresses = try! .init(
							collection: .init(
								uncheckedUniqueElements: [
									.init(value: .init(email: identifiedFieldOutput.value)),
								]
							)
						)
					case let .phoneNumber(entryModel):
						persona.personaData.phoneNumbers = try! .init(
							collection: .init(
								uncheckedUniqueElements: [
									.init(value: .init(number: identifiedFieldOutput.value)),
								]
							)
						)
					case let .url(entryModel): break
					case let .postalAddress(entryModel): break
					case let .creditCard(entryModel): break
					}
				}

				try await personasClient.updatePersona(persona)
				await send(.delegate(.personaSaved(persona)))
				await dismiss()
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .addAFieldButtonTapped:
			state.destination = .addFields(.init(excludedFieldIDs: state.dynamicFields.map(\.entryKind)))
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.addFields(.delegate(.addFields(fieldsToAdd))))):
			state.dynamicFields.append(contentsOf: fieldsToAdd.map {
				.init(
					id: $0.entry,
					text: nil,
					isRequiredByDapp: false,
					entryKind: $0.entry.kind
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
}

extension EditPersona.State {
	func hasChanges() -> Bool {
		guard let output = viewState.output else { return false }
		return output.personaLabel != persona.displayName
			|| fieldsOutput(dynamicFields: persona.personaData.dynamicFields(in: mode)) != output.fields
	}
}

extension PersonaData {
	func dynamicFields(in mode: EditPersona.State.Mode) -> IdentifiedArrayOf<EditPersonaDynamicField.State> {
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
					}(),
					entryKind: entry.value.kind
				)
			}
		)
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
