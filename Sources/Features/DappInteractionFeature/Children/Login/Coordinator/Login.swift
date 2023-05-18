import AuthorizedDappsClient
import CreatePersonaFeature
import DeviceFactorSourceClient
import EngineToolkit
import FeaturePrelude
import PersonasClient
import ROLAClient

// MARK: - Login
struct Login: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
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
			dappMetadata: DappMetadata,
			loginRequest: P2P.Dapp.Request.AuthLoginRequestItem,
			isFirstPersonaOnAnyNetwork: Bool? = nil
		) {
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
		case failedToSignAuthChallenge
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient
	@Dependency(\.rolaClient) var rolaClient
	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

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
			let authorizedPersona = state.authorizedDapp?.referencesToAuthorizedPersonas[id: persona.address]
			guard case let .withChallenge(loginWithChallenge) = state.loginRequest else {
				return .send(.delegate(.continueButtonTapped(persona, state.authorizedDapp, authorizedPersona, nil)))
			}

			let challenge = loginWithChallenge.challenge

			let createAuthPayloadRequest = AuthenticationDataToSignForChallengeRequest(
				challenge: challenge,
				origin: state.dappMetadata.origin,
				dAppDefinitionAddress: state.dappMetadata.dAppDefinitionAddress
			)

			return .run { [authorizedDapp = state.authorizedDapp] send in
				let authToSignResponse = try rolaClient.authenticationDataToSignForChallenge(createAuthPayloadRequest)

				let signature = try await deviceFactorSourceClient.signUsingDeviceFactorSource(
					signerEntity: .persona(persona),
					unhashedDataToSign: authToSignResponse.payloadToHashAndSign,
					purpose: .signAuth
				)
				let signedAuthChallenge = SignedAuthChallenge(challenge: challenge, entitySignatures: Set([signature]))
				await send(.delegate(.continueButtonTapped(persona, authorizedDapp, authorizedPersona, signedAuthChallenge)))
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
		.run { [dAppDefinitionAddress = state.dappMetadata.dAppDefinitionAddress] send in
			let personas = try await personasClient.getPersonas()
			let authorizedDapps = try await authorizedDappsClient.getAuthorizedDapps()
			let authorizedDapp = authorizedDapps[id: dAppDefinitionAddress]
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

extension DappMetadata {
	var dAppDefinitionAddress: DappDefinitionAddress {
		switch self {
		case let .ledger(metadata): return metadata.dAppDefinintionAddress
		case let .request(metadata): return metadata.dAppDefinitionAddress
		}
	}
}
