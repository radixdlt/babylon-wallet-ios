import AccountsClient
import CreateEntityFeature
import FeaturePrelude

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
		var createAccountCoordinator: CreateAccountCoordinator.State?

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
			self.createAccountCoordinator = createAccountCoordinator
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
		case createAccountCoordinator(PresentationAction<CreateAccountCoordinator.Action>)
	}

	enum DelegateAction: Sendable, Equatable {
		case continueButtonTapped(
			accessKind: ChooseAccounts.State.AccessKind,
			chosenAccounts: ChooseAccountsResult
		)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$createAccountCoordinator, action: /Action.child .. ChildAction.createAccountCoordinator) {
				CreateAccountCoordinator()
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
			state.createAccountCoordinator = .init(config: .init(
				purpose: .newAccountDuringDappInteraction
			), displayIntroduction: { _ in false })
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

			loggerGlobal.critical("IGNORING PROOF OF OWNERSHIP, TODO, IMPLEMENT!")
			fatalError("impl me")

			return .send(.delegate(.continueButtonTapped(
				accessKind: state.accessKind,
				chosenAccounts: .withoutProofOfOwnership(selectedAccounts)
			)))
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
		case .createAccountCoordinator(.presented(.delegate(.completed))):
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
