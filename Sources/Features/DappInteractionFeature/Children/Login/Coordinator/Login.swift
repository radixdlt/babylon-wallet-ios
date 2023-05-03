import AuthorizedDappsClient
import CreateEntityFeature
import EngineToolkit
import FeaturePrelude
import PersonasClient

// MARK: - LoginRequest
struct Login: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let dappDefinitionAddress: DappDefinitionAddress
		let dappMetadata: DappMetadata
		let loginRequest: P2P.Dapp.Request.AuthLoginRequestItem

		var isFirstPersonaOnAnyNetwork: Bool? = nil

		var personas: IdentifiedArrayOf<PersonaRow.State> = []
		var authorizedDapp: Profile.Network.AuthorizedDapp?
		var authorizedPersona: Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple?

		var selectedPersona: PersonaRow.State?

		@PresentationState
		var createPersonaCoordinator: CreatePersonaCoordinator.State? = nil

		init(
			dappDefinitionAddress: DappDefinitionAddress,
			dappMetadata: DappMetadata,
			loginRequest: P2P.Dapp.Request.AuthLoginRequestItem,
			isFirstPersonaOnAnyNetwork: Bool? = nil
		) {
			self.dappDefinitionAddress = dappDefinitionAddress
			self.dappMetadata = dappMetadata
			self.loginRequest = loginRequest
			self.isFirstPersonaOnAnyNetwork = isFirstPersonaOnAnyNetwork
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case selectedPersonaChanged(PersonaRow.State?)
		case createNewPersonaButtonTapped
		case continueButtonTapped(Profile.Network.Persona)
	}

	enum InternalAction: Sendable, Equatable {
		case personasLoaded(IdentifiedArrayOf<Profile.Network.Persona>, Profile.Network.AuthorizedDapp?, Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple?)
		case isFirstPersonaOnAnyNetwork(Bool)
	}

	enum ChildAction: Sendable, Equatable {
		case createPersonaCoordinator(PresentationAction<CreatePersonaCoordinator.Action>)
	}

	enum DelegateAction: Sendable, Equatable {
		case continueButtonTapped(
			Profile.Network.Persona,
			Profile.Network.AuthorizedDapp?,
			Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple?,
			SignedAuthChallenge?
		)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$createPersonaCoordinator, action: /Action.child .. ChildAction.createPersonaCoordinator) {
				CreatePersonaCoordinator()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return loadPersonas(state: &state).concatenate(with: checkIfFirstPersonaByUserEver())

		case let .selectedPersonaChanged(persona):
			state.selectedPersona = persona
			return .none

		case .createNewPersonaButtonTapped:
			assert(state.isFirstPersonaOnAnyNetwork != nil, "Should have checked 'isFirstPersonaOnAnyNetwork' already")
			let isFirstOnAnyNetwork = state.isFirstPersonaOnAnyNetwork ?? true

			state.createPersonaCoordinator = .init(config: .init(
				purpose: .newPersonaDuringDappInteract(isFirst: state.personas.isEmpty)
			), displayIntroduction: { _ in isFirstOnAnyNetwork })
			return .none

		case let .continueButtonTapped(persona):
			if let challenge = state.loginRequest.challenge {
				let payloadToHash: String = challenge.rawValue.data.hex() + state.dappDefinitionAddress.address + state.dappMetadata.origin
				let hashToSign = try! blake2b(payloadToHash)
				fatalError("impl sign auth, where")
			} else {
				let authorizedPersona = state.authorizedDapp?.referencesToAuthorizedPersonas[id: persona.address]
				return .send(.delegate(.continueButtonTapped(persona, state.authorizedDapp, authorizedPersona, nil)))
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .isFirstPersonaOnAnyNetwork(isFirstPersonaOnAnyNetwork):
			state.isFirstPersonaOnAnyNetwork = isFirstPersonaOnAnyNetwork
			return .none

		case let .personasLoaded(personas, authorizedDapp, authorizedPersonaSimple):
			let lastLoggedInPersona: Profile.Network.Persona? = {
				if let authorizedPersonaSimple {
					return personas[id: authorizedPersonaSimple.identityAddress]
				} else {
					return nil
				}
			}()
			state.personas = .init(uniqueElements:
				personas.map { persona in
					PersonaRow.State(
						persona: persona,
						lastLogin: persona == lastLoggedInPersona ? authorizedPersonaSimple?.lastLogin : nil
					)
				}
			)
			if
				let lastLoggedInPersona,
				let extractedLastLoggedInPersona = state.personas.remove(id: lastLoggedInPersona.id)
			{
				state.personas.insert(extractedLastLoggedInPersona, at: 0)
			}
			state.authorizedDapp = authorizedDapp
			state.authorizedPersona = authorizedPersonaSimple
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .createPersonaCoordinator(.presented(.delegate(.completed))):
			state.isFirstPersonaOnAnyNetwork = false
			return loadPersonas(state: &state)

		default:
			return .none
		}
	}

	func loadPersonas(state: inout State) -> EffectTask<Action> {
		.run { [dappDefinitionAddress = state.dappDefinitionAddress] send in
			let personas = try await personasClient.getPersonas()
			let authorizedDapps = try await authorizedDappsClient.getAuthorizedDapps()
			let authorizedDapp = authorizedDapps[id: dappDefinitionAddress]
			let authorizedPersona: Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple? = {
				guard let authorizedDapp else {
					return nil
				}
				return personas.reduce(into: nil) { mostRecentlyAuthorizedPersona, currentPersona in
					guard let currentAuthorizedPersona = authorizedDapp.referencesToAuthorizedPersonas[id: currentPersona.address] else {
						return
					}
					if let mostRecentlyAuthorizedPersonaCopy = mostRecentlyAuthorizedPersona {
						if currentAuthorizedPersona.lastLogin > mostRecentlyAuthorizedPersonaCopy.lastLogin {
							mostRecentlyAuthorizedPersona = currentAuthorizedPersona
						}
					} else {
						mostRecentlyAuthorizedPersona = currentAuthorizedPersona
					}
				}
			}()
			await send(.internal(.personasLoaded(personas, authorizedDapp, authorizedPersona)))
		}
	}

	func checkIfFirstPersonaByUserEver() -> EffectTask<Action> {
		.task {
			let hasAnyPersonaOnAnyNetwork = await personasClient.hasAnyPersonaOnAnyNetwork()
			let isFirstPersonaOnAnyNetwork = !hasAnyPersonaOnAnyNetwork
			return .internal(.isFirstPersonaOnAnyNetwork(isFirstPersonaOnAnyNetwork))
		}
	}
}
