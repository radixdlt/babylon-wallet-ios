import AccountsClient
import CreateEntityFeature
import FactorSourcesClient
import FeaturePrelude
import ROLAClient
import SigningFeature

// MARK: - ChooseAccountsResult
typealias ChooseAccountsResult = P2P.Dapp.Response.Accounts

// MARK: - ChooseAccounts
struct ChooseAccounts: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		enum AccessKind: Sendable, Hashable {
			case ongoing
			case oneTime
		}

		/// if `proofOfOwnership`, sign this challenge
		let challenge: P2P.Dapp.Request.AuthChallengeNonce?

		let accessKind: AccessKind
		let dappMetadata: DappMetadata
		var availableAccounts: IdentifiedArrayOf<Profile.Network.Account>
		let numberOfAccounts: DappInteraction.NumberOfAccounts
		var selectedAccounts: [ChooseAccountsRow.State]?

		var _chooseAcounts: _ChooseAccounts.State

		@PresentationState
		var destination: Destinations.State?

		init(
			challenge: P2P.Dapp.Request.AuthChallengeNonce?,
			accessKind: AccessKind,
			dappMetadata: DappMetadata,
			availableAccounts: IdentifiedArrayOf<Profile.Network.Account> = [],
			numberOfAccounts: DappInteraction.NumberOfAccounts,
			selectedAccounts: [ChooseAccountsRow.State]? = nil,
			createAccountCoordinator: CreateAccountCoordinator.State? = nil,
			_chooseAccounts: _ChooseAccounts.State
		) {
			self.challenge = challenge
			self.accessKind = accessKind
			self.dappMetadata = dappMetadata
			self.availableAccounts = availableAccounts
			self.numberOfAccounts = numberOfAccounts
			self.selectedAccounts = selectedAccounts
			self.destination = nil
			self._chooseAcounts = _chooseAccounts
		}
	}

	enum ViewAction: Sendable, Equatable {
		case continueButtonTapped([ChooseAccountsRow.State])
	}

	enum InternalAction: Sendable, Equatable {
		case proveAccountOwnership(SigningFactors, AuthenticationDataToSignForChallengeResponse)
	}

	enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
		case _chooseAccounts(_ChooseAccounts.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case continueButtonTapped(
			accessKind: ChooseAccounts.State.AccessKind,
			chosenAccounts: ChooseAccountsResult
		)
		case failedToProveOwnership(of: [Profile.Network.Account])
	}

	struct Destinations: Sendable, ReducerProtocol {
		enum State: Sendable, Hashable {
			case signing(Signing.State)
		}

		enum Action: Sendable, Equatable {
			case signing(Signing.Action)
		}

		var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.signing, action: /Action.signing) {
				Signing()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.rolaClient) var rolaClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .continueButtonTapped(selectedAccounts):

			let selectedAccounts = IdentifiedArray(uncheckedUniqueElements: selectedAccounts.map(\.account))

			guard let challenge = state.challenge else {
				return .send(.delegate(.continueButtonTapped(
					accessKind: state.accessKind,
					chosenAccounts: .withoutProofOfOwnership(selectedAccounts)
				)))
			}

			guard let signers = NonEmpty<Set<EntityPotentiallyVirtual>>.init(rawValue: Set(selectedAccounts.map { EntityPotentiallyVirtual.account($0) })) else {
				return .send(.delegate(.continueButtonTapped(
					accessKind: state.accessKind,
					chosenAccounts: .withoutProofOfOwnership(selectedAccounts)
				)))
			}

			let createAuthPayloadRequest = AuthenticationDataToSignForChallengeRequest(
				challenge: challenge,
				origin: state.dappMetadata.origin,
				dAppDefinitionAddress: state.dappMetadata.dAppDefinitionAddress
			)

			return .run { send in
				let dataToSign = try rolaClient.authenticationDataToSignForChallenge(createAuthPayloadRequest)
				let networkID = await accountsClient.getCurrentNetworkID()
				let signingFactors = try await factorSourcesClient.getSigningFactors(.init(
					networkID: networkID,
					signers: signers,
					signingPurpose: .signAuth
				))
				await send(.internal(.proveAccountOwnership(signingFactors, dataToSign)))
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .proveAccountOwnership(signingFactors, authenticationDataToSignForChallenge):
			state.destination = .signing(.init(
				factorsLeftToSignWith: signingFactors,
				signingPurposeWithPayload: .signAuth(authenticationDataToSignForChallenge)
			))
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.signing(.delegate(.finishedSigning(.signAuth(signedAuthChallenge)))))):
			state.destination = nil

			var accountsLeftToVerifyDidSign: Set<Profile.Network.Account.ID> = Set((state.selectedAccounts ?? []).map(\.account.id))
			let walletAccountsWithProof: [P2P.Dapp.Response.Accounts.WithProof] = signedAuthChallenge.entitySignatures.map {
				guard case let .account(account) = $0.signerEntity else {
					fatalError()
				}
				accountsLeftToVerifyDidSign.remove(account.id)
				let proof = P2P.Dapp.Response.AuthProof(entitySignature: $0)
				return P2P.Dapp.Response.Accounts.WithProof(account: .init(account: account), proof: proof)
			}
			guard accountsLeftToVerifyDidSign.isEmpty else {
				loggerGlobal.error("Failed to sign with all accounts..")
				return .send(.delegate(.failedToProveOwnership(of: (state.selectedAccounts ?? []).map(\.account))))
			}

			let chosenAccounts: ChooseAccountsResult = .withProofOfOwnership(
				challenge: signedAuthChallenge.challenge,
				IdentifiedArrayOf<P2P.Dapp.Response.Accounts.WithProof>.init(uniqueElements: walletAccountsWithProof)
			)
			return .send(.delegate(.continueButtonTapped(accessKind: state.accessKind, chosenAccounts: chosenAccounts)))

		case .destination(.presented(.signing(.delegate(.failedToSign)))):
			state.destination = nil
			loggerGlobal.error("Failed to sign proof of ownership")
			return .send(.delegate(.failedToProveOwnership(of: (state.selectedAccounts ?? []).map(\.account))))

		case .destination(.presented(.signing(.delegate(.finishedSigning(.signTransaction))))):
			state.destination = nil
			assertionFailure("wrong signing, signed tx, expected auth...")
			loggerGlobal.error("Failed to sign proof of ownership")
			return .send(.delegate(.failedToProveOwnership(of: (state.selectedAccounts ?? []).map(\.account))))

		default:
			return .none
		}
	}
}
