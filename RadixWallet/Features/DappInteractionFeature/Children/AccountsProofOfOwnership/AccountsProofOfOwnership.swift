// MARK: - AccountsProofOfOwnership
@Reducer
struct AccountsProofOfOwnership: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let accountAddresses: [AccountAddress]
		let dappMetadata: DappMetadata
		let challenge: DappToWalletInteractionAuthChallengeNonce

		var accounts: Accounts = []

		init(
			accountAddresses: [AccountAddress],
			dappMetadata: DappMetadata,
			challenge: DappToWalletInteractionAuthChallengeNonce
		) {
			self.accountAddresses = accountAddresses
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
		case setAccounts(Accounts)
	}

	enum DelegateAction: Sendable, Equatable {
		case provenOwnership(Accounts, SignedAuthChallenge)
		case failedToGetAccounts
	}

	@Dependency(\.accountsClient) var accountsClient

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			loadAccountsEffect(state: state)
		case .continueButtonTapped:
			.none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setAccounts(accounts):
			state.accounts = accounts
			return .none
		}
	}

	private func loadAccountsEffect(state: State) -> Effect<Action> {
		.run { send in
			let allAccounts = try await accountsClient.getAccountsOnCurrentNetwork()
			let accounts = allAccounts.filter {
				state.accountAddresses.contains($0.address)
			}
			if accounts.count == state.accountAddresses.count {
				await send(.internal(.setAccounts(accounts)))
			} else {
				await send(.delegate(.failedToGetAccounts))
			}

		} catch: { error, send in
			loggerGlobal.error("Failed to fetch Accounts to prove its ownership, \(error)")
			await send(.delegate(.failedToGetAccounts))
		}
	}
}
