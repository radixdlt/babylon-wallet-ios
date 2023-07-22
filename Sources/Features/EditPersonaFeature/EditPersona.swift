import FeaturePrelude
import PersonasClient
import Prelude

// MARK: - EditPersona.Output
extension EditPersona {
	public struct Output: Sendable, Hashable {
		let personaLabel: NonEmptyString

		let name: EditPersonaName.State?
		let emailAddress: EditPersonaDynamicField.State?
		let phoneNumber: EditPersonaDynamicField.State?

		var personaData: PersonaData {
			var personaData = PersonaData()

			personaData.name = name.map {
				.init(value: .init(
					variant: $0.variant,
					familyName: $0.family.input ?? "",
					givenNames: $0.given.input ?? "",
					nickname: $0.nickName.input
				))
			}

			personaData.emailAddresses = (emailAddress?.input)
				.flatMap { try? .init(collection: [.init(value: .init(email: $0))]) } ?? .init()

			personaData.phoneNumbers = (phoneNumber?.input)
				.flatMap { try? .init(collection: [.init(value: .init(number: $0))]) } ?? .init()

			return personaData
		}
	}
}

// MARK: - EditPersona
public struct EditPersona: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case edit
			case dapp(requiredEntries: Set<EntryKind>)
		}

		public enum StaticFieldID: Sendable, Hashable, Comparable {
			case personaLabel
		}

		let mode: Mode
		let persona: Profile.Network.Persona
		var entries: EditPersonaEntries.State
		var labelField: EditPersonaStaticField.State

		@PresentationState
		var destination: Destinations.State? = nil

		var alreadyAddedEntryKinds: [PersonaData.Entry.Kind] {
			[entries.name?.kind, entries.emailAddress?.kind, entries.phoneNumber?.kind].compactMap(identity)
		}

		public init(
			mode: Mode,
			persona: Profile.Network.Persona
		) {
			self.mode = mode
			self.persona = persona
			self.entries = .init(with: persona.personaData, mode: mode)
			self.labelField = EditPersonaStaticField.State(
				id: .personaLabel,
				initial: persona.displayName.rawValue
			)
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
		case personaData(action: EditPersonaEntries.Action)
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
		Scope(state: \.entries, action: /Action.child .. ChildAction.personaData) {
			EditPersonaEntries()
		}
		Reduce(core)
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
			let alreadyAddedEntryKinds: [PersonaData.Entry.Kind] = state.alreadyAddedEntryKinds
			state.destination = .addFields(.init(excludedEntryKinds: alreadyAddedEntryKinds))
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .destination(.presented(.closeConfirmationDialog(.discardChanges))):
			return .fireAndForget { await dismiss() }

		case let .destination(.presented(.addFields(.delegate(.addEntryKinds(fieldsToAdd))))):
			for kind in fieldsToAdd {
				switch kind {
				case .fullName:
					state.entries.name = .entry()

				case .emailAddress:
					state.entries.emailAddress = try? .singleFieldEntry(kind)

				case .phoneNumber:
					state.entries.phoneNumber = try? .singleFieldEntry(kind)

				default:
					continue
				}
			}
			state.destination = nil
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
			// FIXME: Figure out some better way for diffing. Currently if we'd simply do `output.personaData != persona.personaData` we'd get `false` as `id`s would not match.
			|| output.personaData.name?.value != persona.personaData.name?.value
			|| output.personaData.emailAddresses.first?.value != persona.personaData.emailAddresses.first?.value
			|| output.personaData.phoneNumbers.first?.value != persona.personaData.phoneNumbers.first?.value
	}
}

extension EditPersona.State.Mode {
	var requiredEntries: Set<PersonaData.Entry.Kind> {
		switch self {
		case .edit:
			return []
		case let .dapp(requiredEntries):
			return requiredEntries
		}
	}
}

extension Profile.Network.Persona {
	fileprivate func updated(with output: EditPersona.Output) -> Self {
		var updatedPersona = self

		updatedPersona.displayName = output.personaLabel
		updatedPersona.personaData = output.personaData

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

extension EditPersonaEntry<EditPersonaDynamicField>.State {
	struct NotApplicableError: Error {}

	static func singleFieldEntry(_ kind: PersonaData.Entry.Kind, text: String = "", isRequestedByDapp: Bool = false) throws -> Self {
		switch kind {
		case .fullName, .dateOfBirth, .companyName, .url, .postalAddress, .creditCard:
			throw NotApplicableError()
		case .emailAddress:
			return .init(kind: .emailAddress, field: .emailAddress, text: text, isRequestedByDapp: isRequestedByDapp)
		case .phoneNumber:
			return .init(kind: .phoneNumber, field: .phoneNumber, text: text, isRequestedByDapp: isRequestedByDapp)
		}
	}

	private init(kind: PersonaData.Entry.Kind, field: DynamicFieldID, text: String, isRequestedByDapp: Bool) {
		self.init(
			kind: kind,
			isRequestedByDapp: isRequestedByDapp,
			content: .init(
				id: field,
				text: text,
				isRequiredByDapp: isRequestedByDapp,
				showsName: false
			)
		)
	}
}

extension EditPersonaEntry<EditPersonaName>.State {
	static func entry(
		name: PersonaData.Name = .init(variant: .western, familyName: "", givenNames: ""),
		isRequestedByDapp: Bool = false
	) -> Self {
		.init(
			kind: .fullName,
			isRequestedByDapp: isRequestedByDapp,
			content: .init(with: name, isRequestedByDapp: isRequestedByDapp)
		)
	}
}
