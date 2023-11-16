import ComposableArchitecture
import SwiftUI

// MARK: - Home
public struct Home: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		// MARK: - Components
		public var header: Header.State
		public var accountRows: IdentifiedArrayOf<Home.AccountRow.State>

		// MARK: - Destination
		@PresentationState
		public var destination: Destination.State?

		public init() {
			self.header = .init()
			self.accountRows = []
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
		public typealias HasAccessToMnemonic = Bool
		case accountsLoadedResult(TaskResult<IdentifiedArrayOf<Profile.Network.Account>>)
		case exportMnemonic(account: Profile.Network.Account)
		case importMnemonic
	}

	public enum ChildAction: Sendable, Equatable {
		case header(Header.Action)
		case account(id: Home.AccountRow.State.ID, action: Home.AccountRow.Action)
		case destination(PresentationAction<Destination.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case displaySettings
	}

	public struct Destination: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case accountDetails(AccountDetails.State)
			case createAccount(CreateAccountCoordinator.State)
			case importMnemonics(ImportMnemonicsFlowCoordinator.State)
			case exportMnemonic(ExportMnemonic.State)
		}

		public enum Action: Sendable, Equatable {
			case accountDetails(AccountDetails.Action)
			case createAccount(CreateAccountCoordinator.Action)
			case importMnemonics(ImportMnemonicsFlowCoordinator.Action)
			case exportMnemonic(ExportMnemonic.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.accountDetails, action: /Action.accountDetails) {
				AccountDetails()
			}
			Scope(state: /State.createAccount, action: /Action.createAccount) {
				CreateAccountCoordinator()
			}
			Scope(state: /State.importMnemonics, action: /Action.importMnemonics) {
				ImportMnemonicsFlowCoordinator()
			}
			Scope(state: /State.exportMnemonic, action: /Action.exportMnemonic) {
				ExportMnemonic()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.header, action: /Action.child .. ChildAction.header) {
			Header()
		}
		Reduce(core)
			.forEach(\.accountRows, action: /Action.child .. ChildAction.account) {
				Home.AccountRow()
			}
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destination()
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

			state.accountRows = accounts.map { Home.AccountRow.State(account: $0) }.asIdentifiable()

			return .run { [addresses = state.accountAddresses] _ in
				_ = try await accountPortfoliosClient.fetchAccountPortfolios(addresses, false)
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
			.merge(with: checkAccountsAccessToMnemonic(state: state))

		case let .accountsLoadedResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .exportMnemonic(account):
			return exportMnemonic(controlling: account, state: &state)

		case .importMnemonic:
			return importMnemonics(state: &state)
		}
	}

	private func checkAccountsAccessToMnemonic(state: State) -> Effect<Action> {
		.merge(state.accountRows.map {
			.send(.child(.account(
				id: $0.id,
				action: .internal(.checkAccountAccessToMnemonic)
			)))
		})
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .account(id, action: .delegate(delegateAction)):
			guard let accountRow = state.accountRows[id: id] else { return .none }
			let account = accountRow.account
			switch delegateAction {
			case .openDetails:
				state.destination = .accountDetails(.init(accountWithInfo: accountRow.accountWithInfo))
				return .none
			case .exportMnemonic:
				return exportMnemonic(controlling: account, state: &state)
			case .importMnemonics:
				return importMnemonics(state: &state)
			}

		case let .destination(.presented(.accountDetails(.delegate(.exportMnemonic(controlledAccount))))):
			return dismissAccountDetails(then: .exportMnemonic(account: controlledAccount), &state)

		case .destination(.presented(.accountDetails(.delegate(.importMnemonics)))):
			return dismissAccountDetails(then: .importMnemonic, &state)

		case .destination(.presented(.accountDetails(.delegate(.dismiss)))):
			state.destination = nil
			return .none

		case let .destination(.presented(.exportMnemonic(.delegate(delegateAction)))):
			state.destination = nil
			switch delegateAction {
			case .doneViewing:
				return checkAccountsAccessToMnemonic(state: state)

			case .notPersisted, .persistedMnemonicInKeychainOnly, .persistedNewFactorSourceInProfile:
				assertionFailure("Expected 'doneViewing' action")
				return .none
			}

		case let .destination(.presented(.importMnemonics(.delegate(delegateAction)))):
			state.destination = nil
			switch delegateAction {
			case .finishedEarly: break
			case let .finishedImportingMnemonics(_, imported, newMainBDFS):
				assert(newMainBDFS == nil, "Discrepancy, should not have been able to create new BDFS from outside of onboarding.")
				if !imported.isEmpty {
					return checkAccountsAccessToMnemonic(state: state)
				}
			}
			return .none

		default:
			return .none
		}
	}

	private func dismissAccountDetails(then internalAction: InternalAction, _ state: inout State) -> Effect<Action> {
		state.destination = nil
		return delayedMediumEffect(internal: internalAction)
	}

	private func importMnemonics(state: inout State) -> Effect<Action> {
		state.destination = .importMnemonics(.init())
		return .none
	}

	private func exportMnemonic(
		controlling account: Profile.Network.Account,
		state: inout State
	) -> Effect<Action> {
		exportMnemonic(
			controlling: account,
			onSuccess: {
				state.destination = .exportMnemonic(.export(
					$0,
					title: L10n.RevealSeedPhrase.title,
					context: .fromBackupPrompt
				))
			}
		)
	}
}

extension Home.State {
	public var accounts: IdentifiedArrayOf<Profile.Network.Account> {
		accountRows.map(\.account).asIdentifiable()
	}

	public var accountAddresses: [AccountAddress] {
		accounts.map(\.address)
	}
}
