import FeaturePrelude
import PersonasClient
import Prelude

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
			case dapp(requested: P2P.Dapp.Request.PersonaDataRequestItem)
		}

		public enum StaticFieldID: Sendable, Hashable, Comparable {
			case personaLabel
		}

		public typealias DynamicFieldID = PersonaData.Entry.Kind

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

			for requiredFieldID in mode.requiredFields where dynamicFields[id: requiredFieldID] == nil {
				dynamicFields.append(.init(id: requiredFieldID, text: nil, isRequiredByDapp: true))
			}
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
			case closeConfirmationDialog(ConfirmationDialogState<ViewAction.CloseConfirmationDialogAction>)
			case addFields(EditPersonaAddEntryKinds.State)
		}

		public enum Action: Sendable, Equatable {
			case closeConfirmationDialog(ViewAction.CloseConfirmationDialogAction)
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

			state.destination = .closeConfirmationDialog(
				.init(titleVisibility: .hidden) {
					TextState("")
				} actions: {
					ButtonState(role: .destructive, action: .send(.discardChanges)) {
						TextState(L10n.EditPersona.CloseConfirmationDialog.discardChanges)
					}
					ButtonState(role: .cancel, action: .send(.keepEditing)) {
						TextState(L10n.EditPersona.CloseConfirmationDialog.keepEditing)
					}
				} message: {
					TextState(L10n.EditPersona.CloseConfirmationDialog.message)
				}
			)
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
			state.destination = .addFields(.init(excludedEntryKinds: state.dynamicFields.map(\.id)))
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .destination(.presented(.closeConfirmationDialog(.discardChanges))):
			return .fireAndForget { await dismiss() }

		case let .destination(.presented(.addFields(.delegate(.addEntryKinds(fieldsToAdd))))):
			state.dynamicFields.append(contentsOf: fieldsToAdd.map {
				.init(
					id: $0,
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
}

extension EditPersona.State {
	func hasChanges() -> Bool {
		guard let output = viewState.output else { return false }
		return output.personaLabel != persona.displayName
			|| fieldsOutput(dynamicFields: persona.personaData.dynamicFields(in: mode)) != output.fields
	}
}

// FIXME: This can be simplified, and it seems duplicated
extension PersonaData {
	func dynamicFields(
		in mode: EditPersona.State.Mode
	) -> IdentifiedArrayOf<EditPersonaDynamicField.State> {
		IdentifiedArray(
			uncheckedUniqueElements: entries.map(\.value).map { entryValue in
				EditPersonaDynamicField.State(
					id: entryValue.discriminator,
					text: entryValue.description,
					isRequiredByDapp: mode.requiredFields.contains(entryValue.discriminator)
				)
			}
		)
	}
}

extension EditPersona.State.Mode {
	var requiredFields: Set<EditPersona.State.DynamicFieldID> {
		switch self {
		case .edit:
			return []
		case let .dapp(requested):
			return requiredFieldIDs
		}
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
				// FIXME: `try` and handle errors properly when we will have multiple entries of that kind (as the only reason to throw here is related to multiple values)
				let emailAddresses = try? PersonaData.IdentifiedEmailAddresses(
					collection: .init(
						uncheckedUniqueElements: [
							.init(value: .init(email: identifiedFieldOutput.value)),
						]
					)
				)
				updatedPersona.personaData.emailAddresses = emailAddresses ?? .init()
			case .phoneNumber:
				// FIXME: `try` and handle errors properly when we will have multiple entries of that kind (as the only reason to throw here is related to multiple values)
				let phoneAddresses = try? PersonaData.IdentifiedPhoneNumbers(
					collection: .init(
						uncheckedUniqueElements: [
							.init(value: .init(number: identifiedFieldOutput.value)),
						]
					)
				)
				updatedPersona.personaData.phoneNumbers = phoneAddresses ?? .init()
			case .url: break
			case .postalAddress: break
			case .creditCard: break
			}
		}

		return updatedPersona
	}
}
