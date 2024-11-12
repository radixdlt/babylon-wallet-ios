import Foundation

@Reducer
struct SignProofOfOwnership: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let dappMetadata: DappMetadata
		let challenge: DappToWalletInteractionAuthChallengeNonce

		@Presents
		var destination: Destination.State?

		init(
			dappMetadata: DappMetadata,
			challenge: DappToWalletInteractionAuthChallengeNonce
		) {
			self.dappMetadata = dappMetadata
			self.challenge = challenge
		}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case task
	}

	enum InternalAction: Sendable, Equatable {
		case handle(signers: NonEmpty<Set<AccountOrPersona>>)
		case performSignature(SigningFactors, AuthenticationDataToSignForChallengeResponse)
	}

	enum DelegateAction: Sendable, Equatable {
		case signedChallenge(SignedAuthChallenge)
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

	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.rolaClient) var rolaClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .handle(signers):
			let createAuthPayloadRequest = AuthenticationDataToSignForChallengeRequest(
				challenge: state.challenge,
				origin: state.dappMetadata.origin,
				dAppDefinitionAddress: state.dappMetadata.dAppDefinitionAddress
			)

			return .run { send in
				let signingFactors = try await factorSourcesClient.getSigningFactors(.init(
					networkID: gatewaysClient.getCurrentNetworkID(),
					signers: signers,
					signingPurpose: .signAuth
				))

				let authToSignResponse = try rolaClient.authenticationDataToSignForChallenge(createAuthPayloadRequest)
				await send(.internal(.performSignature(signingFactors, authToSignResponse)))
			} catch: { _, send in
				loggerGlobal.error("Failed to gather signature payloads")
				await send(.delegate(.failedToSign))
			}

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
				return .send(.delegate(.signedChallenge(signedAuthChallenge)))

			case .failedToSign:
				state.destination = nil
				loggerGlobal.error("Failed to sign proof of ownership")
				return .send(.delegate(.failedToSign))

			case .finishedSigning(.signTransaction), .finishedSigning(.signPreAuthorization):
				state.destination = nil
				assertionFailure("Signed a transaction while expecting auth")
				loggerGlobal.error("Signed a transaction while expecting auth")
				return .send(.delegate(.failedToSign))
			}

		default:
			return .none
		}
	}
}
