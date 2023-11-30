// MARK: - AccountRecoveryScanCoordinator

public struct AccountRecoveryScanCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Root: Sendable, Hashable {
			case accountRecoveryScanInProgress(AccountRecoveryScanInProgress.State)
			case selectInactiveAccountsToAdd(SelectInactiveAccountsToAdd.State)
		}

		/// Create new Profile or add accounts
		public let purpose: Purpose

		public var root: Root

		/// Create new Profile or add accounts
		public enum Purpose: Sendable, Hashable {
			case createProfile(PrivateHDFactorSource)

			case addAccounts(
				factorSourceID: FactorSourceID.FromHash,
				olympia: Bool
			)
		}

		public init(purpose: Purpose) {
			self.purpose = purpose

			switch purpose {
			case let .addAccounts(id, forOlympiaAccounts):
				self.root = .accountRecoveryScanInProgress(.init(
					mode: .factorSourceWithID(id: id),
					forOlympiaAccounts: forOlympiaAccounts
				))

			case let .createProfile(privateHDFactorSource):
				self.root = .accountRecoveryScanInProgress(.init(
					mode: .privateHD(privateHDFactorSource),
					forOlympiaAccounts: false
				))
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case accountRecoveryScanInProgress(AccountRecoveryScanInProgress.Action)
		case selectInactiveAccountsToAdd(SelectInactiveAccountsToAdd.Action)
	}

	public enum InternalAction: Sendable, Equatable {
		case createProfileResult(TaskResult<EqVoid>)
		case addAccountsToExistingProfileResult(TaskResult<EqVoid>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed
		case dismissed
	}

	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.onboardingClient) var onboardingClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.dismiss) var dismiss
	public init() {}

	public var body: some ReducerOf<Self> {
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

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeTapped:
			.run { send in
				await dismiss()
				await send(.delegate(.dismissed))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
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

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .accountRecoveryScanInProgress(.delegate(.foundAccounts(active, inactive))):

			if inactive.isEmpty {
				return completed(purpose: state.purpose, active: active, inactive: inactive)
			} else {
				state.root = .selectInactiveAccountsToAdd(.init(active: active, inactive: inactive))
				return .none
			}

		case .accountRecoveryScanInProgress(.delegate(.failedToDerivePublicKey)):
			return .send(.delegate(.dismissed))

		case let .selectInactiveAccountsToAdd(.delegate(.finished(selectedInactive, active))):
			return completed(purpose: state.purpose, active: active, inactive: selectedInactive)

		default: return .none
		}
	}

	private func completed(
		purpose: State.Purpose,
		active: IdentifiedArrayOf<Profile.Network.Account>,
		inactive: IdentifiedArrayOf<Profile.Network.Account>
	) -> Effect<Action> {
		let sortedAccounts: IdentifiedArrayOf<Profile.Network.Account> = { () -> IdentifiedArrayOf<Profile.Network.Account> in
			var accounts = active
			accounts.append(contentsOf: active)
			accounts.sort() // by index
			loggerGlobal.debug("Successfully discovered and created #\(active.count) accounts and #\(inactive.count) inactive accounts that was chosen by user, sorted by index, these are all the accounts we are gonna use:\n\(accounts)")
			return accounts
		}()

		switch purpose {
		case let .createProfile(privateHD):
			let recoveredAccountAndBDFS = AccountsRecoveredFromScanningUsingMnemonic(
				accounts: sortedAccounts,
				deviceFactorSource: privateHD.factorSource
			)
			return .run { send in
				let result = await TaskResult<EqVoid> {
					try secureStorageClient.saveMnemonicForFactorSource(privateHD)
					return try await onboardingClient.finishOnboardingWithRecoveredAccountAndBDFS(recoveredAccountAndBDFS)
				}
				await send(.internal(.createProfileResult(result)))
			}
		case .addAccounts:
			return .run { send in
				let result = await TaskResult<EqVoid> {
					try await accountsClient.saveVirtualAccounts(Array(sortedAccounts))
				}
				await send(.internal(.addAccountsToExistingProfileResult(result)))
			}
		}
	}
}
