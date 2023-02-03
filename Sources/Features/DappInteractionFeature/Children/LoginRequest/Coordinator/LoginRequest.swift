import FeaturePrelude

// MARK: - LoginRequest
public struct LoginRequest: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let dappDefinitionAddress: DappDefinitionAddress
		let dappMetadata: DappMetadata

		var personas: IdentifiedArrayOf<PersonaRow.State> = []
		var authorizedPersona: OnNetwork.ConnectedDapp.AuthorizedPersonaSimple?
		var selectedPersona: OnNetwork.Persona? {
			personas.first(where: { $0.isSelected })?.persona
		}

		public init(
			dappDefinitionAddress: DappDefinitionAddress,
			dappMetadata: DappMetadata
		) {
			self.dappDefinitionAddress = dappDefinitionAddress
			self.dappMetadata = dappMetadata
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case createNewPersonaButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case personasLoaded(IdentifiedArrayOf<OnNetwork.Persona>, OnNetwork.ConnectedDapp.AuthorizedPersonaSimple?)
	}

	public enum ChildAction: Sendable, Equatable {
		case persona(id: PersonaRow.State.ID, action: PersonaRow.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case continueButtonTapped(OnNetwork.Persona, OnNetwork.ConnectedDapp.AuthorizedPersonaSimple?)
	}

	public init() {}

	@Dependency(\.profileClient) var profileClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { [dappDefinitionAddress = state.dappDefinitionAddress] send in
				let personas = try await profileClient.getPersonas()
				let connectedDapps = try await profileClient.getConnectedDapps()
				let authorizedPersona: OnNetwork.ConnectedDapp.AuthorizedPersonaSimple? = {
					guard let connectedDapp = connectedDapps.first(by: dappDefinitionAddress) else {
						return nil
					}
					return personas.reduce(into: nil) { mostRecentlyAuthorizedPersona, currentPersona in
						guard let currentAuthorizedPersona = connectedDapp.referencesToAuthorizedPersonas.first(by: currentPersona.address) else {
							return
						}
						if
							let lastLoginDate = mostRecentlyAuthorizedPersona?.lastLoginDate,
							currentAuthorizedPersona.lastLoginDate > lastLoginDate
						{
							mostRecentlyAuthorizedPersona = currentAuthorizedPersona
						}
					}
				}()
				await send(.internal(.personasLoaded(personas, authorizedPersona)))
			}
		case .createNewPersonaButtonTapped:
			// TODO:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .personasLoaded(personas, authorizedPersona):
			state.authorizedPersona = authorizedPersona
			// TODO: @Nikola map personas to rows, putting the authorized persona up at the top
//			state.personas = ...
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		// TODO: @Nikola this should be:
		// case let .persona(id: id, action: .delegate(.didSelect)):
		//
		// We should never observe non-delegate actions from parent reducers, even
		// if the actions are the same name and shape.
		case let .persona(id: id, action: .view(.didSelect)):
			state.personas.forEach {
				if $0.id == id {
					if !$0.isSelected {
						state.personas[id: $0.id]?.isSelected = true
					}
				} else {
					state.personas[id: $0.id]?.isSelected = false
				}
			}
			return .none
		default:
			return .none
		}
	}
}
