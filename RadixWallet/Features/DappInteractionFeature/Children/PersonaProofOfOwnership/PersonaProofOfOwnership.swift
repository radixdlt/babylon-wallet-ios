// MARK: - PersonaProofOfOwnership
@Reducer
struct PersonaProofOfOwnership: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let identityAddress: IdentityAddress
		let dappMetadata: DappMetadata
		let challenge: DappToWalletInteractionAuthChallengeNonce

		var persona: Persona?

		init(
			identityAddress: IdentityAddress,
			dappMetadata: DappMetadata,
			challenge: DappToWalletInteractionAuthChallengeNonce
		) {
			self.identityAddress = identityAddress
			self.dappMetadata = dappMetadata
			self.challenge = challenge
		}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case task
		case continueButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case setPersona(Persona)
	}

	enum DelegateAction: Sendable, Equatable {
		case provenOwnership(Persona, SignedAuthChallenge)
		case failedToGetPersona
		case failedToSign
	}

	@Dependency(\.personasClient) var personasClient
	@Dependency(\.rolaClient) var rolaClient
	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			loadPersonaEffect(state: state)
		case .continueButtonTapped:
			signChallengeEffect(state: state)
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setPersona(persona):
			state.persona = persona
			return .none
		}
	}

	private func loadPersonaEffect(state: State) -> Effect<Action> {
		.run { send in
			let persona = try await personasClient.getPersona(id: state.identityAddress)
			await send(.internal(.setPersona(persona)))
		} catch: { error, send in
			loggerGlobal.error("Failed to get Persona to proove its ownership, \(error)")
			await send(.delegate(.failedToGetPersona))
		}
	}

	private func signChallengeEffect(state: State) -> Effect<Action> {
		guard let persona = state.persona else {
			return .none
		}
		let createAuthPayloadRequest = AuthenticationDataToSignForChallengeRequest(
			challenge: state.challenge,
			origin: state.dappMetadata.origin,
			dAppDefinitionAddress: state.dappMetadata.dAppDefinitionAddress
		)

		return .run { [challenge = state.challenge] send in
			let authToSignResponse = try rolaClient.authenticationDataToSignForChallenge(createAuthPayloadRequest)

			let signature = try await deviceFactorSourceClient.signUsingDeviceFactorSource(
				signerEntity: .persona(persona),
				hashedDataToSign: authToSignResponse.payloadToHashAndSign.hash(),
				purpose: .signAuth
			)

			let signedAuthChallenge = SignedAuthChallenge(challenge: challenge, entitySignatures: Set([signature]))

			await send(.delegate(.provenOwnership(persona, signedAuthChallenge)))
		} catch: { _, send in
			loggerGlobal.error("Failed to sign proof of ownership")
			await send(.delegate(.failedToSign))
		}
	}
}
