import FeaturePrelude
import PersonasClient
import Prelude

// MARK: - EditPersona.Output
extension EditPersona {
	public struct Output: Sendable, Hashable {
		let personaLabel: NonEmptyString
		let name: EditPersonaName.State?
		let emailAddress: EditPersonaDynamicEntry.State?

		var personaData: PersonaData {
			var personaData = PersonaData()
			(emailAddress?.input).map {
				personaData.emailAddresses = try! .init(collection: [.init(value: .init(email: $0))])
			}
			name.map {
				personaData.name = .init(
					value: .init(
						given: $0.given.input ?? "",
						family: $0.family.input ?? "",
						variant: .eastern
					)
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
		}

		public enum StaticFieldID: Sendable, Hashable, Comparable {
			case personaLabel
		}

		public typealias DynamicFieldID = PersonaData.Entry.Kind

		let mode: Mode
		let persona: Profile.Network.Persona
		var entries: EditPersonaEntries.State
		var labelField: EditPersonaStaticField.State

		@PresentationState
		var destination: Destinations.State? = nil

		var alreadyAddedEntryKinds: [PersonaData.Entry.Kind] {
			[
				entries.name.map { _ in .name },
				entries.emailAddress.map { _ in .emailAddress },
			].compactMap(identity)
		}

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
			self.entries = .init(with: persona.personaData)
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
		Scope(
			state: \.labelField,
			action: /Action.child .. ChildAction.labelField
		) {
			EditPersonaField()
		}

		Scope(
			state: \.entries,
			action: /Action.child .. ChildAction.personaData
		) {
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
			fieldsToAdd.map(\.entry.kind).forEach { entryKind in
				switch entryKind {
				case .name:
					state.entries.name = .init(with: PersonaData.Name(given: "", family: "", variant: .eastern))
				case .dateOfBirth:
					fatalError()
				case .companyName:
					fatalError()
				case .emailAddress:
					state.entries.emailAddress = .init(
						id: entryKind,
						text: nil,
						isRequiredByDapp: false
					)
				case .url:
					fatalError()
				case .phoneNumber:
					fatalError()
				case .postalAddress:
					fatalError()
				case .creditCard:
					fatalError()
				}
			}
			state.destination = nil
			return .none

		case .personaData(action: .child(.emailAddress(.delegate(.delete)))):
			state.entries.emailAddress = nil
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
			|| persona.personaData != output.personaData
	}
}

extension PersonaData {
	func dynamicFields(
		in mode: EditPersona.State.Mode
	) -> IdentifiedArrayOf<EditPersonaDynamicEntry.State> {
		IdentifiedArray(
			uncheckedUniqueElements: entries.map(\.value).map { entryValue in
				EditPersonaDynamicEntry.State(
					id: entryValue.kind,
					text: entryValue.text,
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
