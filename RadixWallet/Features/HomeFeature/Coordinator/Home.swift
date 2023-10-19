import ComposableArchitecture
import SwiftUI

// MARK: - Home
public struct Home: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		// MARK: - Components
		public var babylonAccountRecoveryIsNeeded: Bool
		public var header: Header.State
		public var accountList: AccountList.State
		public var accounts: IdentifiedArrayOf<Profile.Network.Account> {
			.init(uniqueElements: accountList.accounts.map(\.account))
		}

		// MARK: - Destinations
		@PresentationState
		public var destination: Destinations.State?

		public init(
			babylonAccountRecoveryIsNeeded: Bool
		) {
			self.babylonAccountRecoveryIsNeeded = babylonAccountRecoveryIsNeeded
			self.header = .init()
			self.accountList = .init(accounts: [])
			self.destination = nil
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case pullToRefreshStarted
		case createAccountButtonTapped
		case settingsButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case accountsLoadedResult(TaskResult<Profile.Network.Accounts>)
		case mnemonicAccessResult([FactorSourceID.FromHash: Bool])
	}

	public enum ChildAction: Sendable, Equatable {
		case header(Header.Action)
		case accountList(AccountList.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case displaySettings
	}

	public struct Destinations: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case accountDetails(AccountDetails.State)
			case createAccount(CreateAccountCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case accountDetails(AccountDetails.Action)
			case createAccount(CreateAccountCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.accountDetails, action: /Action.accountDetails) {
				AccountDetails()
			}
			Scope(state: /State.createAccount, action: /Action.createAccount) {
				CreateAccountCoordinator()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
	@Dependency(\.secureStorageClient) var secureStorageClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.header, action: /Action.child .. ChildAction.header) {
			Header()
		}
		Scope(state: \.accountList, action: /Action.child .. ChildAction.accountList) {
			AccountList()
		}
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				for try await accounts in await accountsClient.accountsOnCurrentNetwork() {
					guard !Task.isCancelled else { return }
					await send(.internal(.accountsLoadedResult(.success(accounts))))
				}
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
			.merge(with: checkAccountsAccessToMnemonic(state: state))
		case .createAccountButtonTapped:
			state.destination = .createAccount(
				.init(config: .init(
					purpose: .newAccountFromHome
				))
			)
			return .none
		case .pullToRefreshStarted:
			let accountAddresses = state.accounts.map(\.address)
			return .run { _ in
				_ = try await accountPortfoliosClient.fetchAccountPortfolios(accountAddresses, true)
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
		case .settingsButtonTapped:
			return .send(.delegate(.displaySettings))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .accountsLoadedResult(.success(accounts)):
			guard accounts.elements != state.accounts.elements else {
				return .none
			}

			state.accountList = .init(accounts: accounts)
			let accountAddresses = state.accounts.map(\.address)
			return .run { _ in
				_ = try await accountPortfoliosClient.fetchAccountPortfolios(accountAddresses, false)
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
			.merge(with: checkAccountsAccessToMnemonic(state: state))

		case let .accountsLoadedResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		case let .mnemonicAccessResult(result):
			for account in state.accountList.accounts {
				guard var deviceFactorSourceControlled = account.deviceFactorSourceControlled else { continue }

				let hasAccessToMnemonic = result[deviceFactorSourceControlled.factorSourceID] ?? false
				let needToImportMnemonic = if account.isLegacyAccount {
					!hasAccessToMnemonic
				} else {
					state.babylonAccountRecoveryIsNeeded || !hasAccessToMnemonic
				}
				deviceFactorSourceControlled.needToImportMnemonicForThisAccount = needToImportMnemonic
				state.accountList.accounts[id: account.id]?.deviceFactorSourceControlled = deviceFactorSourceControlled
			}
			return .none
		}
	}

	private func checkAccountsAccessToMnemonic(state: State) -> Effect<Action> {
		let factorSourceIDs = Set(state.accounts.compactMap(\.deviceFactorSourceID))
		guard !factorSourceIDs.isEmpty else {
			return .none
		}

		return .run { send in
			let result = await factorSourceIDs.asyncMap { factorSourceID in
				let hasAccessToMnemonic = await secureStorageClient.containsMnemonicIdentifiedByFactorSourceID(factorSourceID)
				return (factorSourceID: factorSourceID, hasAccessToMnemonic: hasAccessToMnemonic)
			}

			let dictionary = result.reduce(into: [:]) {
				$0[$1.factorSourceID] = $1.hasAccessToMnemonic
			}

			await send(.internal(.mnemonicAccessResult(dictionary)))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .accountList(.delegate(.displayAccountDetails(
			account,
			needToBackupMnemonicForThisAccount,
			needToImportMnemonicForThisAccount
		))):

			state.destination = .accountDetails(.init(
				for: account,
				importMnemonicPrompt: .init(needed: needToImportMnemonicForThisAccount),
				exportMnemonicPrompt: .init(needed: needToBackupMnemonicForThisAccount)
			))
			return .none

		case let .accountList(.delegate(.backUpMnemonic(controllingAccount))):
			state.destination = .accountDetails(.init(
				for: controllingAccount,
				exportMnemonicPrompt: .init(needed: true, deepLinkTo: true)
			))
			return .none

		case let .accountList(.delegate(.importMnemonics(account))):
			state.destination = .accountDetails(.init(
				for: account,
				importMnemonicPrompt: .init(needed: true, deepLinkTo: true)
			))
			return .none

		case .destination(.presented(.accountDetails(.delegate(.dismiss)))):
			state.destination = nil
			return .none

		case let .destination(.presented(.accountDetails(.delegate(.importedMnemonic(factorSourceID))))):
			/// Check if the imported mnemonic is a babylon one, so we can reset `babylonAccountRecoveryIsNeeded` flag
			guard let account = state.accounts.first(where: { factorSourceID == $0.deviceFactorSourceID?.embed() }) else {
				return .none
			}
			if !account.isOlympiaAccount {
				state.babylonAccountRecoveryIsNeeded = false
			}
			return .none

		default:
			return .none
		}
	}
}
