import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - CreateAccountCoordinator
struct CreateAccountCoordinator: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var root: Path.State?
		var path: StackState<Path.State> = .init()

		let config: CreateAccountConfig
		var name: NonEmptyString?

		fileprivate var createdProfile = false

		init(
			root: Path.State? = nil,
			config: CreateAccountConfig
		) {
			self.config = config
			if let root {
				self.root = root
			} else {
				self.root = .nameAccount(.init(config: config))
			}
		}

		var shouldDisplayNavBar: Bool {
			switch path.last {
			case .nameAccount, .selectLedger:
				true
			case .completion:
				false
			case .none:
				true
			}
		}
	}

	struct Path: Sendable, Reducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case nameAccount(NameAccount.State)
			case selectLedger(LedgerHardwareDevices.State)
			case completion(NewAccountCompletion.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case nameAccount(NameAccount.Action)
			case selectLedger(LedgerHardwareDevices.Action)
			case completion(NewAccountCompletion.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.nameAccount, action: \.nameAccount) {
				NameAccount()
			}
			Scope(state: \.selectLedger, action: \.selectLedger) {
				LedgerHardwareDevices()
			}
			Scope(state: \.completion, action: \.completion) {
				NewAccountCompletion()
			}
		}
	}

	enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackActionOf<Path>)
	}

	enum InternalAction: Sendable, Equatable {
		case handleAccountCreated(Account)
		case handleProfileCreated(Option)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismissed
		case accountCreated
		case completed
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.onboardingClient) var onboardingClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.isPresented) var isPresented
	@Dependency(\.dismiss) var dismiss

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.root, action: \.child.root) {
				Path()
			}
			.forEach(\.path, action: \.child.path) {
				Path()
			}
	}
}

extension CreateAccountCoordinator {
	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			.run { send in
				await send(.delegate(.dismissed))
				if isPresented {
					await dismiss()
				}
			}
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .root(.nameAccount(.delegate(.proceed(accountName, useLedgerAsFactorSource)))):
			state.name = accountName
			if useLedgerAsFactorSource {
				state.path.append(.selectLedger(.init(context: .createHardwareAccount)))
				return .none
			} else {
				return createProfileIfNecessaryThenCreateAccount(state: &state, option: .bdfs)
			}

		case let .path(.element(_, action: .selectLedger(.delegate(.choseLedger(ledger))))):
			return createProfileIfNecessaryThenCreateAccount(
				state: &state,
				option: .specific(
					ledger.asGeneral
				)
			)

		case .path(.element(_, action: .completion(.delegate(.completed)))):
			return .run { send in
				await send(.delegate(.completed))
				if isPresented {
					await dismiss()
				}
			}

		default:
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .handleAccountCreated(account):
			state.path.append(.completion(.init(
				account: account,
				config: state.config
			)))
			return .send(.delegate(.accountCreated))

		case let .handleProfileCreated(option):
			state.createdProfile = true
			return createAccount(state: &state, option: option)
		}
	}

	private func createProfileIfNecessaryThenCreateAccount(state: inout State, option: Option) -> Effect<Action> {
		if state.config.isNewProfile, !state.createdProfile {
			// We need to create the Profile before creating the Account
			.run { send in
				try await onboardingClient.createNewProfile()
				await send(.internal(.handleProfileCreated(option)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
		} else {
			// We can create the Account since the Profile has been created already
			createAccount(state: &state, option: option)
		}
	}

	private func createAccount(state: inout State, option: Option) -> Effect<Action> {
		guard let name = state.name else {
			fatalError("Name should be set before creating Account")
		}
		let displayName = DisplayName(nonEmpty: name)
		return .run { [networkId = state.config.specificNetworkID] send in
			let account = switch option {
			case .bdfs:
				try await SargonOS.shared.createAccountWithBDFS(networkId: networkId, name: displayName)
			case let .specific(factorSource):
				try await SargonOS.shared.createAccount(factorSource: factorSource, networkId: networkId, name: displayName)
			}

			let updated = await getThirdPartyDepositSettings(account: account)
			await send(.internal(.handleAccountCreated(updated)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	private func getThirdPartyDepositSettings(account: Account) async -> Account {
		do {
			if let updated = try await doAsync(
				withTimeout: .seconds(5),
				work: { try await onLedgerEntitiesClient.syncThirdPartyDepositWithOnLedgerSettings(account: account) }
			) {
				loggerGlobal.notice("Used OnLedger ThirdParty Deposit Settings")
				return updated
			} else {
				return account
			}
		} catch {
			loggerGlobal.notice("Failed to get OnLedger state for newly created account: \(account). Will add it with default third party deposit settings...")
			return account
		}
	}
}

// MARK: CreateAccountCoordinator.Option
extension CreateAccountCoordinator {
	enum Option: Sendable, Hashable {
		case bdfs
		case specific(FactorSource)
	}
}
