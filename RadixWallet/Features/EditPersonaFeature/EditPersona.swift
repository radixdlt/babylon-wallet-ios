import ComposableArchitecture
import Sargon
import SwiftUI

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
				.init(
					id: $0.id,
					value: .init(
						variant: $0.variant,
						familyName: $0.family.input ?? "",
						givenNames: $0.given.input ?? "",
						nickname: $0.nickname.input ?? ""
					)
				)
			}

			if let emailState = emailAddress, let emailAddress = emailState.input {
				personaData.emailAddresses = .init(
					collection: [
						.init(
							id: emailState.entryID,
							value: .init(email: emailAddress)
						),
					]
				)
			}

			if let phoneState = phoneNumber, let phoneNumber = phoneState.input {
				personaData.phoneNumbers = .init(
					collection: [
						.init(
							id: phoneState.entryID,
							value: .init(number: phoneNumber)
						),
					]
				)
			}

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
		let persona: Persona
		var entries: EditPersonaEntries.State
		var labelField: EditPersonaStaticField.State

		@PresentationState
		var destination: Destination.State? = nil

		var alreadyAddedEntryKinds: [PersonaData.Entry.Kind] {
			[entries.name?.kind, entries.emailAddress?.kind, entries.phoneNumber?.kind].compactMap(identity)
		}

		public init(
			mode: Mode,
			persona: Persona
		) {
			self.mode = mode
			self.persona = persona
			self.entries = .init(with: persona.personaData, mode: mode)
			self.labelField = EditPersonaStaticField.State(
				behaviour: .personaLabel,
				entryID: persona.personaData.name?.id,
				initial: persona.displayName.value
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
		case entries(EditPersonaEntries.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case personaSaved(Persona)
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case closeConfirmationDialog(ConfirmationDialogState<ViewAction.CloseConfirmationDialogAction>)
			case addFields(EditPersonaAddEntryKinds.State)
		}

		public enum Action: Sendable, Equatable {
			case closeConfirmationDialog(ViewAction.CloseConfirmationDialogAction)
			case addFields(EditPersonaAddEntryKinds.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.addFields, action: /Action.addFields) {
				EditPersonaAddEntryKinds()
			}
		}
	}

	public init() {}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.errorQueue) var errorQueue

	public var body: some ReducerOf<Self> {
		Scope(state: \.labelField, action: /Action.child .. ChildAction.labelField) {
			EditPersonaField()
		}
		Scope(state: \.entries, action: /Action.child .. ChildAction.entries) {
			EditPersonaEntries()
		}
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			guard state.hasChanges() else {
				return .run { _ in
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
				try await authorizedDappsClient.removeBrokenReferencesToSharedPersonaData(
					personaCurrent: state.persona,
					personaUpdated: updatedPersona
				)
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

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .closeConfirmationDialog(.discardChanges):
			return .run { _ in await dismiss() }

		case let .addFields(.delegate(.addEntryKinds(fieldsToAdd))):
			for kind in fieldsToAdd {
				switch kind {
				case .fullName:
					state.entries.name = .entry(
						entryID: nil,
						name: .default
					)

				case .emailAddress:
					state.entries.emailAddress = try? .singleFieldEntry(entryID: nil, kind)

				case .phoneNumber:
					state.entries.phoneNumber = try? .singleFieldEntry(entryID: nil, kind)

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

extension PersonaDataEntryName {
	static let `default` = Self(
		variant: .western,
		familyName: "",
		givenNames: "",
		nickname: ""
	)
}

extension EditPersona.State {
	func hasChanges() -> Bool {
		guard let output = viewState.output else { return false }
		return output.personaLabel.rawValue != persona.displayName.rawValue
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
			[]
		case let .dapp(requiredEntries):
			requiredEntries
		}
	}
}

extension Persona {
	fileprivate func updated(with output: EditPersona.Output) -> Self {
		var updatedPersona = self

		updatedPersona.displayName = Sargon.DisplayName(value: output.personaLabel.rawValue)
		updatedPersona.personaData = output.personaData

		return updatedPersona
	}
}

extension PersonaData.Entry {
	// FIXME: Use proper values and granularity (Entry-, instead of Field-level) when Entry types will be supported
	var text: String {
		switch self {
		case let .name(entryModel): entryModel.description
		case let .emailAddress(entryModel): entryModel.email
		case let .phoneNumber(entryModel): entryModel.number
		default: fatalError("Add support for new PersonaData entry kinds")
		}
	}
}

extension EditPersonaEntry<EditPersonaDynamicField>.State {
	struct NotApplicableError: Error {}

	static func singleFieldEntry(
		entryID: PersonaDataEntryID?,
		_ kind: PersonaData.Entry.Kind,
		text: String = "",
		isRequestedByDapp: Bool = false
	) throws -> Self {
		switch kind {
		case .fullName:
			throw NotApplicableError()

		case .emailAddress:
			return .init(
				entryID: entryID,
				kind: .emailAddress,
				field: .emailAddress,
				text: text,
				isRequestedByDapp: isRequestedByDapp
			)

		case .phoneNumber:
			return .init(
				entryID: entryID,
				kind: .phoneNumber,
				field: .phoneNumber,
				text: text,
				isRequestedByDapp: isRequestedByDapp
			)
		}
	}

	private init(
		entryID: PersonaDataEntryID?,
		kind: PersonaData.Entry.Kind,
		field: DynamicFieldID,
		text: String,
		isRequestedByDapp: Bool
	) {
		self.init(
			kind: kind,
			isRequestedByDapp: isRequestedByDapp,
			content: .init(
				behaviour: field,
				entryID: entryID,
				text: text,
				isRequiredByDapp: isRequestedByDapp,
				showsTitle: false
			)
		)
	}
}

extension EditPersonaEntry<EditPersonaName>.State {
	static func entry(
		entryID: PersonaDataEntryID?,
		name: PersonaDataEntryName,
		isRequestedByDapp: Bool = false
	) -> Self {
		.init(
			kind: .fullName,
			isRequestedByDapp: isRequestedByDapp,
			content: .init(
				entryID: entryID,
				with: name,
				isRequestedByDapp: isRequestedByDapp
			)
		)
	}
}

extension PersonaData.Entry {
	var kind: Kind {
		switch self {
		case .name: .fullName
		case .emailAddress: .emailAddress
		case .phoneNumber: .phoneNumber
		}
	}
}
