// MARK: - AccountRecoveryScanCoordinator

struct AccountRecoveryScanCoordinator: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		enum Root: Sendable, Hashable {
			case accountRecoveryScanInProgress(AccountRecoveryScanInProgress.State)
			case selectInactiveAccountsToAdd(SelectInactiveAccountsToAdd.State)
		}

		/// Create new Profile or add accounts
		let purpose: Purpose

		var root: Root

		// FIXME: Clean this up! we are temporily force to use
		// tree based navigation with `root` since SwiftUI did not
		// like our 9 levels deep navigation tree when coming here
		// from onboarding. We really wanted to use a NavigationStack
		// here, but that broke the feature, so until we flatten nav
		// depth of onboarding we need tree based, but we wanna be
		// able to go back from `selectInactiveAccountsToAdd` screen
		// to `accountRecoveryScanInProgress`, this is the easiest
		// way to preserve the exact state of that screen....
		var backTo: AccountRecoveryScanInProgress.State?

		/// Create new Profile or add accounts
		enum Purpose: Sendable, Hashable {
			case createProfile(PrivateHierarchicalDeterministicFactorSource)

			case addAccounts(
				factorSourceID: FactorSourceIDFromHash,
				olympia: Bool
			)
		}

		static func accountRecoveryScanInProgressState(purpose: Purpose) -> AccountRecoveryScanInProgress.State {
			switch purpose {
			case let .addAccounts(id, forOlympiaAccounts):
				AccountRecoveryScanInProgress.State(
					mode: .addAccounts(factorSourceId: id),
					forOlympiaAccounts: forOlympiaAccounts
				)

			case let .createProfile(privateHDFactorSource):
				AccountRecoveryScanInProgress.State(
					mode: .createProfile(privateHDFactorSource),
					forOlympiaAccounts: false
				)
			}
		}

		init(purpose: Purpose) {
			self.purpose = purpose
			self.root = .accountRecoveryScanInProgress(Self.accountRecoveryScanInProgressState(purpose: purpose))
		}
	}

	enum ChildAction: Sendable, Equatable {
		case accountRecoveryScanInProgress(AccountRecoveryScanInProgress.Action)
		case selectInactiveAccountsToAdd(SelectInactiveAccountsToAdd.Action)
	}

	enum InternalAction: Sendable, Equatable {
		case createProfileResult(TaskResult<EqVoid>)
		case addAccountsToExistingProfileResult(TaskResult<EqVoid>)
	}

	enum DelegateAction: Sendable, Equatable {
		case completed
		case dismissed
	}

	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.onboardingClient) var onboardingClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.userDefaults) var userDefaults

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.root, action: /Action.child) {
			EmptyReducer()
				.ifCaseLet(/State.Root.accountRecoveryScanInProgress, action: /ChildAction.accountRecoveryScanInProgress) {
					AccountRecoveryScanInProgress()
				}
				.ifCaseLet(/State.Root.selectInactiveAccountsToAdd, action: /ChildAction.selectInactiveAccountsToAdd) {
					SelectInactiveAccountsToAdd()
				}
		}
		Reduce(core)
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .addAccountsToExistingProfileResult(.success):
			loggerGlobal.notice("Successfully added accounts to existing profile using Account Recovery Scanning ✅")
			return .send(.delegate(.completed))
		case let .addAccountsToExistingProfileResult(.failure(error)):
			loggerGlobal.error("Failed to add accoutns to existing profile, error: \(error)")
			return .send(.delegate(.dismissed))
		case .createProfileResult(.success):
			loggerGlobal.notice("Successfully created a Profile using Account Recovery Scanning ✅")
			return .send(.delegate(.completed))
		case let .createProfileResult(.failure(error)):
			loggerGlobal.error("Failed to add accoutns to existing profile, error: \(error)")
			return .send(.delegate(.dismissed))
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .accountRecoveryScanInProgress(.delegate(.foundAccounts(active, inactive, deleted))):
			switch state.root {
			case let .accountRecoveryScanInProgress(childState):
				state.backTo = childState
			case .selectInactiveAccountsToAdd: assertionFailure("Discrepancy, wrong state")
			}
			if inactive.isEmpty {
				return completed(
					purpose: state.purpose,
					active: active,
					inactive: inactive,
					deleted: deleted
				)
			} else {
				withAnimation {
					state.root = .selectInactiveAccountsToAdd(.init(
						active: active,
						deleted: deleted,
						inactive: inactive
					))
				}
				return .none
			}

		case .accountRecoveryScanInProgress(.delegate(.close)),
		     .accountRecoveryScanInProgress(.delegate(.failed)):
			return .send(.delegate(.dismissed))

		case .selectInactiveAccountsToAdd(.delegate(.goBack)):
			let childState = state.backTo ?? AccountRecoveryScanCoordinator.State.accountRecoveryScanInProgressState(purpose: state.purpose)
			state.root = .accountRecoveryScanInProgress(childState)
			return .none

		case let .selectInactiveAccountsToAdd(.delegate(.finished(selectedInactive, active, deleted))):
			return completed(
				purpose: state.purpose,
				active: active,
				inactive: selectedInactive,
				deleted: deleted
			)

		default:
			return .none
		}
	}

	private func completed(
		purpose: State.Purpose,
		active: IdentifiedArrayOf<Account>,
		inactive: IdentifiedArrayOf<Account>,
		deleted: IdentifiedArrayOf<Account>
	) -> Effect<Action> {
		let sortedAccounts: Accounts = { () -> IdentifiedArrayOf<Account> in
			var accounts = active
			accounts.append(contentsOf: inactive)
			accounts.append(contentsOf: deleted)
			accounts.sort() // by index
			loggerGlobal.debug("Successfully discovered and created #\(active.count) accounts and #\(inactive.count) inactive accounts that was chosen by user, sorted by index, these are all the accounts we are gonna use:\n\(accounts)")
			return accounts
		}()

		switch purpose {
		case let .createProfile(privateHD):
			let recoveredAccountAndBDFS = AccountsRecoveredFromScanningUsingMnemonic(
				accounts: sortedAccounts,
				factorSource: privateHD
			)
			return .run { send in
				let result = await TaskResult<EqVoid> {
					// Not important enough to throw.
					try? userDefaults.addFactorSourceIDOfBackedUpMnemonic(privateHD.factorSource.id)

					return try await onboardingClient.finishOnboardingWithRecoveredAccountAndBDFS(recoveredAccountAndBDFS)
				}
				await send(.internal(.createProfileResult(result)))
			}
		case .addAccounts:
			return .run { send in
				let result = await TaskResult<EqVoid> {
					try await accountsClient.saveVirtualAccounts(
						sortedAccounts
					)
				}
				await send(.internal(.addAccountsToExistingProfileResult(result)))
			}
		}
	}
}
