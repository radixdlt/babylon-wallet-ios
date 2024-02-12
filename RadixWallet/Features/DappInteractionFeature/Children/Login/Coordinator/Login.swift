import ComposableArchitecture
import SwiftUI

// MARK: - Login
struct Login: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let dappMetadata: DappMetadata
		let loginRequest: P2P.Dapp.Request.AuthLoginRequestItem

		var personaPrimacy: PersonaPrimacy? = nil

		var personas: IdentifiedArrayOf<PersonaRow.State> = []
		var authorizedDapp: Profile.Network.AuthorizedDapp?
		var authorizedPersona: Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple?

		var selectedPersona: PersonaRow.State?

		@PresentationState
		var createPersonaCoordinator: CreatePersonaCoordinator.State? = nil

		init(
			dappMetadata: DappMetadata,
			loginRequest: P2P.Dapp.Request.AuthLoginRequestItem,
			personaPrimacy: PersonaPrimacy? = nil
		) {
			self.dappMetadata = dappMetadata
			self.loginRequest = loginRequest
			self.personaPrimacy = personaPrimacy
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
		case personaPrimacyDetermined(PersonaPrimacy)
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

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$createPersonaCoordinator, action: /Action.child .. ChildAction.createPersonaCoordinator) {
				CreatePersonaCoordinator()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return loadPersonas(state: &state).concatenate(with: determinePersonaPrimacy())

		case let .selectedPersonaChanged(persona):
			state.selectedPersona = persona
			return .none

		case .createNewPersonaButtonTapped:
			assert(state.personaPrimacy != nil, "Should have checked 'personaPrimacy' already")
			let personaPrimacy = state.personaPrimacy ?? .firstOnAnyNetwork

			state.createPersonaCoordinator = .init(config: .init(personaPrimacy: personaPrimacy, navigationButtonCTA: .goBackToChoosePersonas))
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
					hashedDataToSign: Sargon.hash(data: authToSignResponse.payloadToHashAndSign),
					purpose: .signAuth
				)
				let signedAuthChallenge = SignedAuthChallenge(challenge: challenge, entitySignatures: Set([signature]))
				await send(.delegate(.continueButtonTapped(persona, authorizedDapp, authorizedPersona, signedAuthChallenge)))
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .personaPrimacyDetermined(personaPrimacy):
			state.personaPrimacy = personaPrimacy
			return .none

		case let .personasLoaded(personas, authorizedDapp, authorizedPersonaSimple):
			let lastLoggedInPersona: Profile.Network.Persona? = if let authorizedPersonaSimple {
				personas[id: authorizedPersonaSimple.identityAddress]
			} else {
				nil
			}
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

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .createPersonaCoordinator(.presented(.delegate(.completed))):
			state.personaPrimacy = .notFirstOnCurrentNetwork
			return loadPersonas(state: &state)

		default:
			return .none
		}
	}

	func loadPersonas(state: inout State) -> Effect<Action> {
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

	func determinePersonaPrimacy() -> Effect<Action> {
		.run { send in
			await send(.internal(.personaPrimacyDetermined(
				personasClient.determinePersonaPrimacy()
			)))
		}
	}
}

extension DappMetadata {
	var dAppDefinitionAddress: DappDefinitionAddress {
		switch self {
		case let .ledger(metadata): metadata.dAppDefinintionAddress
		case let .request(metadata): metadata.dAppDefinitionAddress
		case .wallet: .wallet
		}
	}
}
