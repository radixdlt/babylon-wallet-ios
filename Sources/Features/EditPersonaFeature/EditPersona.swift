import FeaturePrelude
import Profile

// MARK: - EditPersona
public struct EditPersona: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case edit
			case dapp(requiredFields: [DynamicField])
		}

		public enum StaticField: Sendable, Hashable, Comparable {
			case personaLabel
		}

		public typealias DynamicField = Profile.Network.Persona.Field.Kind

		var labelField: EditPersonaStaticField.State
		@Sorted(by: \.kind)
		var dynamicFields: IdentifiedArrayOf<EditPersonaDynamicField.State> = []

		@PresentationState
		var destination: Destinations.State? = nil

		public init(
			mode: Mode,
			personaLabel: NonEmptyString,
			existingFields: IdentifiedArrayOf<Profile.Network.Persona.Field>
		) {
			self.labelField = EditPersonaStaticField.State(
				kind: .personaLabel,
				initial: personaLabel.rawValue
			)
			self.dynamicFields = IdentifiedArray(
				uncheckedUniqueElements: existingFields.map { field in
					EditPersonaDynamicField.State(
						kind: field.kind,
						initial: field.value.rawValue,
						isRequiredByDapp: {
							switch mode {
							case .edit:
								return false
							case let .dapp(requiredFields):
								return requiredFields.contains(field.kind)
							}
						}()
					)
				}
			)
			if case let .dapp(requiredFields) = mode {
				for requiredField in requiredFields where dynamicFields[id: requiredField] == nil {
					dynamicFields.append(.init(kind: requiredField, initial: nil, isRequiredByDapp: true))
				}
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case cancelButtonTapped
		case saveButtonTapped
		case addAFieldButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case labelField(EditPersonaStaticField.Action)
		case dynamicField(id: EditPersonaDynamicField.State.ID, action: EditPersonaDynamicField.Action)
		case destination(PresentationAction<Destinations.Action>)
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
		case .saveButtonTapped:
			// TODO:
			return .none
		case .addAFieldButtonTapped:
			state.destination = .addFields(.init(excludedFields: state.dynamicFields.map(\.id)))
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.addFields(.delegate(.addFields(fieldsToAdd))))):
			state.dynamicFields.append(contentsOf: fieldsToAdd.map { .init(kind: $0, initial: nil, isRequiredByDapp: false) })
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}
