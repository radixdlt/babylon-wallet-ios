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
				scheme: DerivationScheme
			)

			public static func addAccountsWithBabylonFactorSource(
				id: FactorSourceID.FromHash
			) -> Self {
				.addAccounts(factorSourceID: id, scheme: .slip10)
			}

			public static func addAccountsWithOlympiaFactorSource(
				id: FactorSourceID.FromHash
			) -> Self {
				.addAccounts(factorSourceID: id, scheme: .bip44)
			}
		}

		public init(purpose: Purpose) {
			self.purpose = purpose
			switch purpose {
			case let .addAccounts(id, scheme):
				self.root = .accountRecoveryScanInProgress(
					.init(
						mode: .factorSourceWithID(id: id),
						scheme: scheme
					)
				)
			case let .createProfile(privateHDFactorSource):
				self.root = .accountRecoveryScanInProgress(
					.init(
						mode: .privateHD(privateHDFactorSource),
						scheme: .slip10
					)
				)
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
			return .send(.delegate(.completed))
		case let .addAccountsToExistingProfileResult(.failure(error)):
			fatalError("todo error handling")
		case .createProfileResult(.success):
			loggerGlobal.notice("Successfully created a Profile using Account Recovery Scanning ✅")
			return .send(.delegate(.completed))
		case let .createProfileResult(.failure(error)):
			fatalError("todo error handling")
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .accountRecoveryScanInProgress(.delegate(.foundAccounts(active, inactive))):
			state.root = .selectInactiveAccountsToAdd(.init(active: active, inactive: inactive))
			return .none
		case .accountRecoveryScanInProgress(.delegate(.failedToDerivePublicKey)):
			return .send(.delegate(.dismissed))

		case let .selectInactiveAccountsToAdd(.delegate(.finished(selectedInactive, active))):
			return completed(purpose: state.purpose, inactiveToAdd: selectedInactive, active: active)

		default: return .none
		}
	}

	private func completed(
		purpose: State.Purpose,
		inactiveToAdd: IdentifiedArrayOf<Profile.Network.Account>,
		active: IdentifiedArrayOf<Profile.Network.Account>
	) -> Effect<Action> {
		// FIXME: check with Matt - should we by default we add ALL accounts, even inactive?
		var all = active
		all.append(contentsOf: inactiveToAdd)
		let accounts = all

		switch purpose {
		case let .createProfile(privateHD):
			loggerGlobal.notice("Successfully discovered and created #\(active.count) accounts and #\(inactiveToAdd.count) inactive accounts that was chosen by user.")
			let recoveredAccountAndBDFS = AccountsRecoveredFromScanningUsingMnemonic(
				accounts: accounts,
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
					try await accountsClient.saveVirtualAccounts(Array(accounts))
				}
				await send(.internal(.addAccountsToExistingProfileResult(result)))
			}
		}
	}
}
