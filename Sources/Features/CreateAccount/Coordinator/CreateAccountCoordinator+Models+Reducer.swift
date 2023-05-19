import Cryptography
import DerivePublicKeyFeature
import FactorSourcesClient
import FeaturePrelude

// MARK: - CreateAccountCoordinator
public struct CreateAccountCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var root: Destinations.State?
		var path: StackState<Destinations.State> = []

		public let config: CreateAccountConfig

		public init(
			root: Destinations.State? = nil,
			config: CreateAccountConfig
		) {
			self.config = config
			if let root {
				self.root = root
			} else {
				self.root = .step1_nameAccount(.init(config: config))
			}
		}

		var shouldDisplayNavBar: Bool {
			guard config.canBeDismissed else {
				return false
			}
			if let last = path.last {
				if case .step3_completion = last {
					return false
				} else if case let .step2_creationOfAccount(creationOfAccount) = last {
					return creationOfAccount.isCreatingLedgerAccount
				} else {
					return true
				}
			}
			return true
		}
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case step_first
			case step_last

			case step1_nameAccount(NameAccount.State)
			case step2_creationOfAccount(CreationOfAccount.State)
			case step3_completion(NewAccountCompletion.State)
		}

		public enum Action: Sendable, Equatable {
			case step1_nameAccount(NameAccount.Action)
			case step2_creationOfAccount(CreationOfAccount.Action)
			case step3_completion(NewAccountCompletion.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.step1_nameAccount, action: /Action.step1_nameAccount) {
				NameAccount()
			}
			Scope(state: /State.step2_creationOfAccount, action: /Action.step2_creationOfAccount) {
				CreationOfAccount()
			}
			Scope(state: /State.step3_completion, action: /Action.step3_completion) {
				NewAccountCompletion()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadFactorSourcesResult(
			TaskResult<FactorSources>,
			beforeCreatingAccountWithName: NonEmptyString,
			useLedgerAsFactorSource: Bool
		)
	}

	public enum ChildAction: Sendable, Equatable {
		case root(Destinations.Action)
		case path(StackAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismissed
		case completed
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dismiss) var dismiss

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.root, action: /Action.child .. ChildAction.root) {
				Destinations()
			}
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Destinations()
			}
	}
}

extension CreateAccountCoordinator {
	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			assert(state.config.canBeDismissed)
			return .run { send in
				await send(.delegate(.dismissed))
				await dismiss()
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadFactorSourcesResult(.failure(error), _, _):
			loggerGlobal.error("Failed to load factor sources: \(error)")
			errorQueue.schedule(error)
			return .none

		case let .loadFactorSourcesResult(.success(factorSources), accountName, useLedgerAsFactorSource):
			precondition(!factorSources.isEmpty)

			let babylonDeviceFactorSources = factorSources.babylonDeviceFactorSources()
			let ledgerFactorSources: [FactorSource] = factorSources.filter { $0.kind == .ledgerHQHardwareWallet }
			let source: GenesisFactorSourceSelection = useLedgerAsFactorSource ? .ledger(ledgerFactorSources: .init(uniqueElements: ledgerFactorSources)) : .device(babylonDeviceFactorSources.first)

			return goToStep2Creation(
				accountName: accountName,
				genesisFactorSourceSelection: source,
				state: &state
			)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .root(.step1_nameAccount(.delegate(.proceed(accountName, useLedgerAsFactorSource)))):

			return .run { send in
				await send(.internal(
					.loadFactorSourcesResult(
						TaskResult {
							try await factorSourcesClient.getFactorSources()
						},
						beforeCreatingAccountWithName: accountName,
						useLedgerAsFactorSource: useLedgerAsFactorSource
					)
				))
			}

		case let .path(.element(_, action: .step2_creationOfAccount(.delegate(.createdAccount(newAccount))))):
			return goToStep3Completion(
				account: newAccount,
				state: &state
			)

		case .path(.element(_, action: .step2_creationOfAccount(.delegate(.createAccountFailed)))):
			state.path.removeLast()
			return .none

		case .path(.element(_, action: .step3_completion(.delegate(.completed)))):
			return .run { send in
				await send(.delegate(.completed))
				await dismiss()
			}

		default:
			return .none
		}
	}

	private func goToStep2Creation(
		accountName: NonEmptyString,
		genesisFactorSourceSelection: GenesisFactorSourceSelection,
		state: inout State
	) -> EffectTask<Action> {
//		let creationOfAccountState = CreationOfAccount.State(
//			name: accountName,
//			derivePublicKey: .init(
//				derivationPathOption: .nextBasedOnFactorSource(
//					networkOption: state.config.specificNetworkID.map { .specific($0) } ?? .useCurrent
//				),
//				factorSourceOption: {
//					switch genesisFactorSourceSelection {
//					case let .device(babylonDevice):
//						return .specific(factorSource: babylonDevice.factorSource)
//					case let .ledger(ledgers):
//						return .anyOf(factorSources: ledgers)
//					}
//				}()
//			)
//		)
		//		state.path.append(.step2_creationOfAccount(creationOfAccountState))
		fatalError()
		return .none
	}

	private func goToStep3Completion(
		account: Profile.Network.Account,
		state: inout State
	) -> EffectTask<Action> {
		state.path.append(.step3_completion(.init(
			account: account,
			config: state.config
		)))
		return .none
	}
}

// MARK: - GenesisFactorSourceSelection
public enum GenesisFactorSourceSelection: Sendable, Hashable {
	case device(BabylonDeviceFactorSource)
	case ledger(ledgerFactorSources: IdentifiedArrayOf<FactorSource>)
}
