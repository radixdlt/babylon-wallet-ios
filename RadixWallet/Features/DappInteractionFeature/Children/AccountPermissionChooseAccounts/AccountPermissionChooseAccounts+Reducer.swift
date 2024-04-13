import ComposableArchitecture
import SwiftUI

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
		var destination: Destination.State?

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
		case chooseAccounts(ChooseAccounts.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case `continue`(
			accessKind: AccountPermissionChooseAccounts.State.AccessKind,
			chosenAccounts: AccountPermissionChooseAccountsResult
		)
		case failedToProveOwnership(of: [Sargon.Account])
	}

	public struct Destination: DestinationReducer {
		enum State: Sendable, Hashable {
			case signing(Signing.State)
		}

		enum Action: Sendable, Equatable {
			case signing(Signing.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: /State.signing, action: /Action.signing) {
				Signing()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.rolaClient) var rolaClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	var body: some ReducerOf<Self> {
		Scope(state: \.chooseAccounts, action: /Action.child .. ChildAction.chooseAccounts) {
			ChooseAccounts()
		}

		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .continueButtonTapped(selectedAccounts):
			let selectedAccounts = IdentifiedArray(uncheckedUniqueElements: selectedAccounts.map(\.account))

			guard let challenge = state.challenge else {
				return .send(.delegate(.continue(
					accessKind: state.accessKind,
					chosenAccounts: .withoutProofOfOwnership(selectedAccounts)
				)))
			}

			guard let signers = NonEmpty<Set<AccountOrPersona>>(rawValue: Set(selectedAccounts.map { AccountOrPersona.account($0) })) else {
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

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .proveAccountOwnership(signingFactors, authenticationDataToSignForChallenge):
			state.destination = .signing(.init(
				factorsLeftToSignWith: signingFactors,
				signingPurposeWithPayload: .signAuth(authenticationDataToSignForChallenge)
			))
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		let selectedAccounts = (state.chooseAccounts.selectedAccounts ?? []).map(\.account)

		switch presentedAction {
		case let .signing(.delegate(signingAction)):
			switch signingAction {
			case .cancelSigning:
				state.destination = nil
				return cancelSigningEffect(state: &state)

			case let .finishedSigning(.signAuth(signedAuthChallenge)):
				state.destination = nil

				var accountsLeftToVerifyDidSign: Set<Sargon.Account.ID> = Set(selectedAccounts.map(\.id))
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
					walletAccountsWithProof.asIdentified()
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

		default:
			return .none
		}
	}

	func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		if case .signing = state.destination {
			cancelSigningEffect(state: &state)
		} else {
			.none
		}
	}

	private func cancelSigningEffect(state: inout State) -> Effect<Action> {
		// FIXME: How to cancel?
		loggerGlobal.error("Cancelled signing")
		return .none
	}
}
