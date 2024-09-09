import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - Login
struct Login: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let dappMetadata: DappMetadata
		let loginRequest: DappToWalletInteractionAuthRequestItem

		var personaPrimacy: PersonaPrimacy? = nil

		var personas: IdentifiedArrayOf<PersonaRow.State> = []
		var authorizedDapp: AuthorizedDapp?
		var authorizedPersona: AuthorizedPersonaSimple?

		var selectedPersona: PersonaRow.State?

		@PresentationState
		var createPersonaCoordinator: CreatePersonaCoordinator.State? = nil

		init(
			dappMetadata: DappMetadata,
			loginRequest: DappToWalletInteractionAuthRequestItem,
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
		case continueButtonTapped(Persona)
	}

	enum InternalAction: Sendable, Equatable {
		typealias SelectedPersonaID = IdentityAddress

		case personasLoaded(
			Personas,
			SelectedPersonaID?,
			AuthorizedDapp?,
			AuthorizedPersonaSimple?
		)
		case personaPrimacyDetermined(PersonaPrimacy)
	}

	enum ChildAction: Sendable, Equatable {
		case createPersonaCoordinator(PresentationAction<CreatePersonaCoordinator.Action>)
	}

	enum DelegateAction: Sendable, Equatable {
		case continueButtonTapped(
			Persona,
			AuthorizedDapp?,
			AuthorizedPersonaSimple?,
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
			return loadPersonas(state: state).concatenate(with: determinePersonaPrimacy())

		case let .selectedPersonaChanged(persona):
			state.selectedPersona = persona
			return .none

		case .createNewPersonaButtonTapped:
			assert(state.personaPrimacy != nil, "Should have checked 'personaPrimacy' already")
			let personaPrimacy = state.personaPrimacy ?? .firstOnAnyNetwork

			state.createPersonaCoordinator = .init(config: .init(personaPrimacy: personaPrimacy, navigationButtonCTA: .goBackToChoosePersonas))
			return .none

		case let .continueButtonTapped(persona):
			let authorizedPersona = state.authorizedDapp?.referencesToAuthorizedPersonas.first(where: { $0.id == persona.id })
			guard case let .loginWithChallenge(loginWithChallenge) = state.loginRequest else {
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
					hashedDataToSign: authToSignResponse.payloadToHashAndSign.hash(),
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

		case let .personasLoaded(personas, selectedPersonaID, authorizedDapp, authorizedPersonaSimple):
			let lastLoggedInPersona: Persona? = if let authorizedPersonaSimple {
				personas[id: authorizedPersonaSimple.identityAddress]
			} else {
				nil
			}
			state.personas = personas.map { persona in
				PersonaRow.State(
					persona: persona,
					lastLogin: persona == lastLoggedInPersona ? authorizedPersonaSimple?.lastLogin : nil
				)
			}
			.asIdentified()

			if
				let lastLoggedInPersona,
				let extractedLastLoggedInPersona = state.personas.remove(id: lastLoggedInPersona.id)
			{
				state.personas.insert(extractedLastLoggedInPersona, at: 0)
			}
			state.authorizedDapp = authorizedDapp
			state.authorizedPersona = authorizedPersonaSimple

			if let selectedPersona = state.personas.first(where: { $0.id == selectedPersonaID }) {
				state.selectedPersona = selectedPersona
			} else if state.selectedPersona == nil {
				state.selectedPersona = state.personas.first
			}

			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .createPersonaCoordinator(.presented(.delegate(.completed(persona)))):
			state.personaPrimacy = .notFirstOnCurrentNetwork
			return loadPersonas(state: state, selectedPersonaID: persona.id)

		default:
			return .none
		}
	}

	func loadPersonas(state: State, selectedPersonaID: IdentityAddress? = nil) -> Effect<Action> {
		.run { [dAppDefinitionAddress = state.dappMetadata.dAppDefinitionAddress] send in
			let personas = try await personasClient.getPersonas()
			let authorizedDapps = try await authorizedDappsClient.getAuthorizedDapps()
			let authorizedDapp = authorizedDapps[id: dAppDefinitionAddress]
			let authorizedPersona: AuthorizedPersonaSimple? = { () -> AuthorizedPersonaSimple? in
				guard let authorizedDapp else {
					return nil
				}
				return personas.reduce(into: nil) { mostRecentlyAuthorizedPersona, currentPersona in
					guard let currentAuthorizedPersona = authorizedDapp.referencesToAuthorizedPersonas.asIdentified()[id: currentPersona.address] else {
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
			await send(.internal(.personasLoaded(personas, selectedPersonaID, authorizedDapp, authorizedPersona)))
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
		case let .request(metadata): metadata.dappDefinitionAddress
		case .wallet: .wallet
		}
	}
}
