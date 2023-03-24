import FeaturePrelude
import Profile

// MARK: - EditPersona.Output
extension EditPersona {
	public struct Output: Sendable, Hashable {
		let personaLabel: NonEmptyString
		let fields: IdentifiedArrayOf<Profile.Network.Persona.Field>
	}
}

// MARK: - EditPersona
public struct EditPersona: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case edit
			case dapp(requiredFieldIDs: Set<DynamicFieldID>)
		}

		public enum StaticFieldID: Sendable, Hashable, Comparable {
			case personaLabel
		}

		public typealias DynamicFieldID = Profile.Network.Persona.Field.ID

		let avatarURL: URL
		var labelField: EditPersonaStaticField.State
		@Sorted(by: \.id)
		var dynamicFields: IdentifiedArrayOf<EditPersonaDynamicField.State> = []

		@PresentationState
		var destination: Destinations.State? = nil

		public init(
			mode: Mode,
			avatarURL: URL,
			personaLabel: NonEmptyString,
			existingFields: IdentifiedArrayOf<Profile.Network.Persona.Field>
		) {
			self.avatarURL = avatarURL
			self.labelField = EditPersonaStaticField.State(
				id: .personaLabel,
				initial: personaLabel.rawValue
			)
			self.dynamicFields = IdentifiedArray(
				uncheckedUniqueElements: existingFields.map { field in
					EditPersonaDynamicField.State(
						id: field.id,
						initial: field.value.rawValue,
						isRequiredByDapp: {
							switch mode {
							case .edit:
								return false
							case let .dapp(requiredFieldIDs):
								return requiredFieldIDs.contains(field.id)
							}
						}()
					)
				}
			)
			if case let .dapp(requiredFieldIDs) = mode {
				for requiredFieldID in requiredFieldIDs where dynamicFields[id: requiredFieldID] == nil {
					dynamicFields.append(.init(id: requiredFieldID, initial: nil, isRequiredByDapp: true))
				}
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case cancelButtonTapped
		case saveButtonTapped(Output)
		case addAFieldButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case labelField(EditPersonaStaticField.Action)
		case dynamicField(id: EditPersonaDynamicField.State.ID, action: EditPersonaDynamicField.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case save(Output)
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
		}
	}

	public init() {}

	@Dependency(\.dismiss) var dismiss

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
		case .cancelButtonTapped:
			return .run { _ in await dismiss() }

		case let .saveButtonTapped(output):
			return .send(.delegate(.save(output)))

		case .addAFieldButtonTapped:
			state.destination = .addFields(.init(excludedFieldIDs: state.dynamicFields.map(\.id)))
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.addFields(.delegate(.addFields(fieldsToAdd))))):
			state.dynamicFields.append(contentsOf: fieldsToAdd.map { .init(id: $0, initial: nil, isRequiredByDapp: false) })
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
