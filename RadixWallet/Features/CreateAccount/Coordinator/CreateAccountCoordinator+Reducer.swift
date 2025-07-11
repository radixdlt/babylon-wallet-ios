import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - CreateAccountCoordinator
@Reducer
struct CreateAccountCoordinator: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var root: Path.State
		var path: StackState<Path.State> = .init()

		let config: CreateAccountConfig
		var name: NonEmptyString?

		init(
			config: CreateAccountConfig
		) {
			self.config = config
			self.root = .nameAccount(.init(config: config))
		}

		var shouldDisplayNavBar: Bool {
			switch path.last {
			case .nameAccount, .selectFactorSource:
				true
			case .completion:
				false
			case .none:
				true
			}
		}
	}

	typealias Action = FeatureAction<Self>

	@Reducer(state: .hashable, action: .equatable)
	enum Path {
		case nameAccount(NameAccount)
		case selectFactorSource(SelectFactorSource)
		case completion(NewAccountCompletion)
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
		Scope(state: \.root, action: \.child.root) {
			Path.nameAccount(.init())
		}

		Reduce(core)
			.forEach(\.path, action: \.child.path)
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
		case let .root(.nameAccount(.delegate(.proceed(accountName)))):
			state.name = accountName
			state.path.append(.selectFactorSource(.init(context: .createAccount)))
			return .none

		case let .path(.element(_, action: .selectFactorSource(.delegate(.selectedFactorSource(fs))))):
			return createAccount(state: &state, factorSource: fs)

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
		}
	}

	private func createAccount(state: inout State, factorSource: FactorSource) -> Effect<Action> {
		guard let name = state.name else {
			fatalError("Name should be set before creating Account")
		}
		let displayName = DisplayName(nonEmpty: name)
		return .run { [networkId = state.config.specificNetworkID] send in
			let account = try await SargonOS.shared.createAccount(factorSource: factorSource, networkId: networkId, name: displayName)

			let updated = await getThirdPartyDepositSettings(account: account)
			// TODO: Remove once this is implemented in Sargon (https://radixdlt.atlassian.net/browse/ABW-4147)
			try? await SargonOS.shared.updateAccount(updated: updated)
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

// MARK: CreateAccountCoordinator.Mode
extension CreateAccountCoordinator {
	enum Mode: Sendable, Hashable {
		case bdfs
		case specific(FactorSource)
	}
}
