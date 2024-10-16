// MARK: - PersonaProofOfOwnership
@Reducer
struct PersonaProofOfOwnership: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let identityAddress: IdentityAddress
		let dappMetadata: DappMetadata
		let challenge: DappToWalletInteractionAuthChallengeNonce

		var persona: Persona?

		@Presents
		var destination: Destination.State?

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
		case performSignature(SigningFactors, AuthenticationDataToSignForChallengeResponse)
	}

	enum DelegateAction: Sendable, Equatable {
		case provenOwnership(Persona, SignedAuthChallenge)
		case failedToGetPersona
		case failedToSign
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case signing(Signing.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case signing(Signing.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.signing, action: \.signing) {
				Signing()
			}
		}
	}

	@Dependency(\.personasClient) var personasClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.rolaClient) var rolaClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			loadPersonaEffect(state: state)
		case .continueButtonTapped:
			gatherSignaturePayloadsEffect(state: state)
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setPersona(persona):
			state.persona = persona
			return .none
		case let .performSignature(signingFactors, authToSignResponse):
			state.destination = .signing(.init(
				factorsLeftToSignWith: signingFactors,
				signingPurposeWithPayload: .signAuth(authToSignResponse)
			))
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .signing(.delegate(signingAction)):
			switch signingAction {
			case .cancelSigning:
				// If the user cancels the signing flow, we just dismiss the `Signing` view and wllow them
				// to retry by tapping Continue again.
				state.destination = nil
				return .none

			case let .finishedSigning(.signAuth(signedAuthChallenge)):
				state.destination = nil
				guard let persona = state.persona else {
					return .none
				}

				return .send(.delegate(.provenOwnership(persona, signedAuthChallenge)))

			case .failedToSign:
				state.destination = nil
				loggerGlobal.error("Failed to sign proof of ownership")
				return .send(.delegate(.failedToSign))

			case .finishedSigning(.signTransaction):
				state.destination = nil
				assertionFailure("Signed a transaction while expecting auth")
				loggerGlobal.error("Signed a transaction while expecting auth")
				return .send(.delegate(.failedToSign))
			}

		default:
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

	private func gatherSignaturePayloadsEffect(state: State) -> Effect<Action> {
		guard
			let persona = state.persona,
			let signers = NonEmpty<Set<AccountOrPersona>>(rawValue: .init([AccountOrPersona.persona(persona)]))
		else {
			return .send(.delegate(.failedToGetPersona))
		}

		let createAuthPayloadRequest = AuthenticationDataToSignForChallengeRequest(
			challenge: state.challenge,
			origin: state.dappMetadata.origin,
			dAppDefinitionAddress: state.dappMetadata.dAppDefinitionAddress
		)

		return .run { send in
			let signingFactors = try await factorSourcesClient.getSigningFactors(.init(
				networkID: accountsClient.getCurrentNetworkID(),
				signers: signers,
				signingPurpose: .signAuth
			))

			let authToSignResponse = try rolaClient.authenticationDataToSignForChallenge(createAuthPayloadRequest)
			await send(.internal(.performSignature(signingFactors, authToSignResponse)))
		}
	}
}
