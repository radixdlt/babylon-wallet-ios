import ComposableArchitecture
import SwiftUI

// MARK: - Home
public struct Home: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		// MARK: - Components
		public var babylonAccountRecoveryIsNeeded: Bool
		public var header: Header.State
		public var accountRows: IdentifiedArrayOf<Home.AccountRow.State>
		public var accounts: IdentifiedArrayOf<Profile.Network.Account> {
			accountRows.map(\.account).asIdentifiable()
		}

		public var accountAddresses: [AccountAddress] {
			accounts.map(\.address)
		}

		// MARK: - Destination
		@PresentationState
		public var destination: Destination.State?

		public init(
			babylonAccountRecoveryIsNeeded: Bool
		) {
			self.babylonAccountRecoveryIsNeeded = babylonAccountRecoveryIsNeeded
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
	@Dependency(\.secureStorageClient) var secureStorageClient

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
				state.destination = .accountDetails(.init(account: account))
				return .none
			case .exportMnemonic:
				return exportMnemonic(controlling: account, state: &state)
			case .importMnemonics:
				return importMnemonics(state: &state)
			}

		case let .destination(.presented(.accountDetails(.delegate(.exportMnemonic(controlledAccount))))):
			return exportMnemonic(controlling: controlledAccount, state: &state)

		case .destination(.presented(.accountDetails(.delegate(.importMnemonics)))):
			return importMnemonics(state: &state)

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
			case let .finishedImportingMnemonics(_, imported):
				if !imported.isEmpty {
					return checkAccountsAccessToMnemonic(state: state)
				}
			}
			return .none

		default:
			return .none
		}
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
					title: L10n.RevealSeedPhrase.title
				))
			}
		)
	}

	private func securityCheckOfAccounts() -> Effect<Action> {
//		.send(.child(.accountList(.internal(.performAccountSecurityCheck))))
		fatalError()
	}
}

extension FeatureReducer {
	func exportMnemonic(
		controlling account: Profile.Network.Account,
		notifyIfMissing: Bool = true,
		onSuccess: (SimplePrivateFactorSource) -> Void
	) -> Effect<Action> {
		guard let txSigningFI = account.virtualHierarchicalDeterministicFactorInstances.first(where: { $0.factorSourceID.kind == .device }) else {
			loggerGlobal.notice("Discrepancy, non software account has not mnemonic to export")
			return .none
		}

		return exportMnemonic(
			factorSourceID: txSigningFI.factorSourceID,
			notifyIfMissing: notifyIfMissing,
			onSuccess: onSuccess
		)
	}

	func exportMnemonic(
		factorSourceID: FactorSource.ID.FromHash,
		notifyIfMissing: Bool = true,
		onSuccess: (SimplePrivateFactorSource) -> Void,
		onError: (Swift.Error) -> Void = { error in
			loggerGlobal.error("Failed to load mnemonic to export: \(error)")
		}
	) -> Effect<Action> {
		@Dependency(\.secureStorageClient) var secureStorageClient
		do {
			guard let mnemonicWithPassphrase = try secureStorageClient.loadMnemonic(
				factorSourceID: factorSourceID,
				purpose: .displaySeedPhrase,
				notifyIfMissing: notifyIfMissing
			) else {
				onError(FailedToFindFactorSource())
				return .none
			}

			onSuccess(
				.init(
					mnemonicWithPassphrase: mnemonicWithPassphrase,
					factorSourceID: factorSourceID
				)
			)

		} catch {
			onError(error)
		}
		return .none
	}
}

extension ExportMnemonic.State {
	static func export(
		_ input: SimplePrivateFactorSource,
		title: String
	) -> Self {
		self.init(
			header: .init(
				title: title
			),
			warning: L10n.RevealSeedPhrase.warning,
			mnemonicWithPassphrase: input.mnemonicWithPassphrase,
			readonlyMode: .init(
				context: .fromSettings,
				factorSourceKind: input.factorSourceID.kind
			)
		)
	}
}

// MARK: - SimplePrivateFactorSource
struct SimplePrivateFactorSource: Sendable, Hashable {
	let mnemonicWithPassphrase: MnemonicWithPassphrase
	let factorSourceID: FactorSource.ID.FromHash
}
