import ChooseAccountsFeature
import FactorSourcesClient
import FeaturePrelude
import ROLAClient
import SigningFeature

// MARK: - ChooseAccountsResult
typealias AccountPermissionChooseAccountsResult = P2P.Dapp.Response.Accounts

// MARK: - AccountPermissionChooseAccounts
struct AccountPermissionChooseAccounts: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		enum AccessKind: Sendable, Hashable {
			case ongoing
			case oneTime
		}

		/// if `proofOfOwnership`, sign this challenge
		let challenge: P2P.Dapp.Request.AuthChallengeNonce?

		let accessKind: AccessKind
		let dappMetadata: DappMetadata
		var chooseAccounts: ChooseAccounts.State

		@PresentationState
		var destination: Destinations.State?

		init(
			challenge: P2P.Dapp.Request.AuthChallengeNonce?,
			accessKind: AccessKind,
			dappMetadata: DappMetadata,
			chooseAccounts: ChooseAccounts.State
		) {
			self.challenge = challenge
			self.accessKind = accessKind
			self.dappMetadata = dappMetadata
			self.chooseAccounts = chooseAccounts
		}

		init(
			challenge: P2P.Dapp.Request.AuthChallengeNonce?,
			accessKind: AccessKind,
			dappMetadata: DappMetadata,
			numberOfAccounts: DappInteraction.NumberOfAccounts
		) {
			self.init(
				challenge: challenge,
				accessKind: accessKind,
				dappMetadata: dappMetadata,
				chooseAccounts: .init(selectionRequirement: .init(numberOfAccounts))
			)
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
		case chooseAccounts(ChooseAccounts.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case `continue`(
			accessKind: AccountPermissionChooseAccounts.State.AccessKind,
			chosenAccounts: AccountPermissionChooseAccountsResult
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
		Scope(state: \.chooseAccounts, action: /Action.child .. ChildAction.chooseAccounts) {
			ChooseAccounts()
		}

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
				return .send(.delegate(.continue(
					accessKind: state.accessKind,
					chosenAccounts: .withoutProofOfOwnership(selectedAccounts)
				)))
			}

			guard let signers = NonEmpty<Set<EntityPotentiallyVirtual>>.init(rawValue: Set(selectedAccounts.map { EntityPotentiallyVirtual.account($0) })) else {
				return .send(.delegate(.continue(
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
		let selectedAccounts = (state.chooseAccounts.selectedAccounts ?? []).map(\.account)

		switch childAction {
		case let .destination(.presented(.signing(.delegate(signingAction)))):
			switch signingAction {
			case .cancelSigning:
				state.destination = nil
				return cancelSigningEffect(state: &state)

			case let .finishedSigning(.signAuth(signedAuthChallenge)):
				state.destination = nil

				var accountsLeftToVerifyDidSign: Set<Profile.Network.Account.ID> = Set(selectedAccounts.map(\.id))
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
					return .send(.delegate(.failedToProveOwnership(of: selectedAccounts)))
				}

				let chosenAccounts: AccountPermissionChooseAccountsResult = .withProofOfOwnership(
					challenge: signedAuthChallenge.challenge,
					IdentifiedArrayOf<P2P.Dapp.Response.Accounts.WithProof>.init(uniqueElements: walletAccountsWithProof)
				)
				return .send(.delegate(.continue(accessKind: state.accessKind, chosenAccounts: chosenAccounts)))

			case .failedToSign:
				state.destination = nil
				loggerGlobal.error("Failed to sign proof of ownership")
				return .send(.delegate(.failedToProveOwnership(of: selectedAccounts)))

			case .finishedSigning(.signTransaction):
				state.destination = nil
				assertionFailure("wrong signing, signed tx, expected auth...")
				loggerGlobal.error("Failed to sign proof of ownership")
				return .send(.delegate(.failedToProveOwnership(of: selectedAccounts)))
			}

		case .destination(.dismiss):
			if case .signing = state.destination {
				return cancelSigningEffect(state: &state)
			} else {
				return .none
			}

		default:
			return .none
		}
	}

	private func cancelSigningEffect(state: inout State) -> EffectTask<Action> {
		// FIXME: How to cancel?
		loggerGlobal.error("Cancelled signing")
		return .none
	}
}
