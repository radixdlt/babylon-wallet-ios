import AccountsClient
import CreateEntityFeature
import FeaturePrelude
import ROLAClient
import SigningFeature

// MARK: - ChooseAccountsResult
enum ChooseAccountsResult: Sendable, Hashable {
	case withoutProofOfOwnership(IdentifiedArrayOf<Profile.Network.Account>)
	case withProofOfOwnership(challenge: P2P.Dapp.AuthChallengeNonce, IdentifiedArrayOf<P2P.Dapp.Response.WalletAccountWithProof>)
}

// MARK: - ChooseAccounts
struct ChooseAccounts: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		enum AccessKind: Sendable, Hashable {
			case ongoing
			case oneTime
		}

		/// if `proofOfOwnership`, sign this challenge
		let challenge: P2P.Dapp.AuthChallengeNonce?

		let accessKind: AccessKind
		let dappDefinitionAddress: DappDefinitionAddress
		let dappMetadata: DappMetadata
		var availableAccounts: IdentifiedArrayOf<Profile.Network.Account>
		let numberOfAccounts: DappInteraction.NumberOfAccounts
		var selectedAccounts: [ChooseAccountsRow.State]?

		@PresentationState
		var destination: Destinations.State?

		init(
			challenge: P2P.Dapp.AuthChallengeNonce?,
			accessKind: AccessKind,
			dappDefinitionAddress: DappDefinitionAddress,
			dappMetadata: DappMetadata,
			availableAccounts: IdentifiedArrayOf<Profile.Network.Account> = [],
			numberOfAccounts: DappInteraction.NumberOfAccounts,
			selectedAccounts: [ChooseAccountsRow.State]? = nil,
			createAccountCoordinator: CreateAccountCoordinator.State? = nil
		) {
			self.challenge = challenge
			self.accessKind = accessKind
			self.dappDefinitionAddress = dappDefinitionAddress
			self.dappMetadata = dappMetadata
			self.availableAccounts = availableAccounts
			self.numberOfAccounts = numberOfAccounts
			self.selectedAccounts = selectedAccounts
			if let createAccountCoordinator {
				self.destination = .createAccount(createAccountCoordinator)
			}
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case createAccountButtonTapped
		case selectedAccountsChanged([ChooseAccountsRow.State]?)
		case continueButtonTapped([ChooseAccountsRow.State])
	}

	enum InternalAction: Sendable, Equatable {
		case loadAccountsResult(TaskResult<Profile.Network.Accounts>)
	}

	enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	enum DelegateAction: Sendable, Equatable {
		case continueButtonTapped(
			accessKind: ChooseAccounts.State.AccessKind,
			chosenAccounts: ChooseAccountsResult
		)
	}

	struct Destinations: Sendable, ReducerProtocol {
		enum State: Sendable, Hashable {
			case createAccount(CreateAccountCoordinator.State)
			case signing(Signing.State)
		}

		enum Action: Sendable, Equatable {
			case createAccount(CreateAccountCoordinator.Action)
			case signing(Signing.Action)
		}

		var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.createAccount, action: /Action.createAccount) {
				CreateAccountCoordinator()
			}
			Scope(state: /State.signing, action: /Action.signing) {
				Signing()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.rolaClient) var rolaClient

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				await send(.internal(.loadAccountsResult(TaskResult {
					try await accountsClient.getAccountsOnCurrentNetwork()
				})))
			}

		case .createAccountButtonTapped:
			state.destination = .createAccount(.init(config: .init(
				purpose: .newAccountDuringDappInteraction
			), displayIntroduction: { _ in false }))
			return .none

		case let .selectedAccountsChanged(selectedAccounts):
			state.selectedAccounts = selectedAccounts
			return .none

		case let .continueButtonTapped(selectedAccounts):
			let selectedAccounts = IdentifiedArray(uncheckedUniqueElements: selectedAccounts.map(\.account))

			guard let challenge = state.challenge else {
				return .send(.delegate(.continueButtonTapped(
					accessKind: state.accessKind,
					chosenAccounts: .withoutProofOfOwnership(selectedAccounts)
				)))
			}

			let createAuthPayloadRequest = AuthenticationDataToSignForChallengeRequest(
				challenge: challenge,
				origin: state.dappMetadata.origin,
				dAppDefinitionAddress: state.dappDefinitionAddress
			)

			return .run { _ in
				let dataToSign = try await rolaClient.authenticationDataToSignForChallenge(createAuthPayloadRequest)
				let networkID = await accountsClient.getCurrentNetworkID()
			}

//			state.destination = .signing(Signing.State.init(networkID: , manifest: <#T##TransactionManifest#>, feePayerSelectionAmongstCandidates: <#T##FeePayerSelectionAmongstCandidates#>, purpose: <#T##SigningPurpose#>))
			fatalError()

//			let signAuthRequest = SignAuthChallengeRequest(
//				challenge: challenge,
//				origin: state.dappMetadata.origin,
//				dAppDefinitionAddress: state.dappDefinitionAddress,
//				entities: .init(uniqueElements: selectedAccounts.elements.map { .account($0) })
//			)

//			return .run { [accessKind = state.accessKind] send in
//				let signedAuthChallenge = try await rolaClient.signAuthChallenge(signAuthRequest)
//				let walletAccountsWithProof: [P2P.Dapp.Response.WalletAccountWithProof] = signedAuthChallenge.entitySignatures.map {
//					guard case let .account(account) = $0.signerEntity else {
//						fatalError()
//					}
//					guard let proof = P2P.Dapp.AuthProof(entitySignature: $0) else {
//						fatalError()
//					}
//					return P2P.Dapp.Response.WalletAccountWithProof(account: .init(account: account), proof: proof)
//				}
//				let chosenAccounts: ChooseAccountsResult = .withProofOfOwnership(
//					challenge: challenge,
//					IdentifiedArrayOf<P2P.Dapp.Response.WalletAccountWithProof>.init(uniqueElements: walletAccountsWithProof)
//				)
//
//				await send(.delegate(.continueButtonTapped(
//					accessKind: accessKind,
//					chosenAccounts: chosenAccounts
//				)))
//
//			} catch: { error, _ in
//				loggerGlobal.error("Failed to sign auth challenge, error: \(error)")
//				errorQueue.schedule(error)
//				fatalError("impl failure")
//				//                await send(.delegate(.failedToSign)
//			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadAccountsResult(.success(accounts)):
			state.availableAccounts = .init(uniqueElements: accounts)
			return .none

		case let .loadAccountsResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .destination(.presented(.createAccount(.delegate(.completed)))):
			return .run { send in
				await send(.internal(.loadAccountsResult(TaskResult {
					try await accountsClient.getAccountsOnCurrentNetwork()
				})))
			}

		default:
			return .none
		}
	}
}
