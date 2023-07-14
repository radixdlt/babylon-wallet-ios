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
	}

	public enum DelegateAction: Sendable, Equatable {
		case personaSaved(Profile.Network.Persona)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {}

		public enum Action: Sendable, Equatable {}

		public var body: some ReducerProtocolOf<Self> {
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
				try await personasClient.updatePersona(persona)
				await send(.delegate(.personaSaved(persona)))
				await dismiss()
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .addAFieldButtonTapped:
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

extension EditPersona.State {
	func fieldsOutput(
		dynamicFields: IdentifiedArrayOf<EditPersonaDynamicField.State>
	) -> IdentifiedArrayOf<Identified<EditPersonaDynamicField.State.ID, String>>? {
		var fieldsOutput: IdentifiedArrayOf<Identified<EditPersonaDynamicField.State.ID, String>> = []
		for field in dynamicFields {
			guard let fieldInput = field.input else {
				if field.kind == .dynamic(isRequiredByDapp: true) {
					return nil
				} else {
					continue
				}
			}
			let fieldOutput = fieldInput.trimmingWhitespace()
			fieldsOutput[id: field.id] = .init(fieldOutput, id: field.id)
		}

		return fieldsOutput
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
					}()
				)
			}
		)
	}
}
