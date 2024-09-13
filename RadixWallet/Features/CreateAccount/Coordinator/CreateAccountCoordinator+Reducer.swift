import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - CreateAccountCoordinator
public struct CreateAccountCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var root: Path.State?
		var path: StackState<Path.State> = .init()

		@PresentationState
		public var destination: Destination.State? = nil

		public let config: CreateAccountConfig
		var name: NonEmptyString?
		var useLedgerAsFactorSource: Bool = false

		public init(
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

	public struct Path: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case nameAccount(NameAccount.State)
			case selectLedger(LedgerHardwareDevices.State)
			case completion(NewAccountCompletion.State)
		}

		public enum Action: Sendable, Equatable {
			case nameAccount(NameAccount.Action)
			case selectLedger(LedgerHardwareDevices.Action)
			case completion(NewAccountCompletion.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.nameAccount, action: /Action.nameAccount) {
				NameAccount()
			}
			Scope(state: /State.selectLedger, action: /Action.selectLedger) {
				LedgerHardwareDevices()
			}
			Scope(state: /State.completion, action: /Action.completion) {
				NewAccountCompletion()
			}
		}
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case derivePublicKey(DerivePublicKeys.State)
		}

		public enum Action: Sendable, Hashable {
			case derivePublicKey(DerivePublicKeys.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.derivePublicKey, action: /Action.derivePublicKey) {
				DerivePublicKeys()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackActionOf<Path>)
	}

	public enum InternalAction: Sendable, Equatable {
		case createAccountResult(TaskResult<Account>)
		case handleAccountCreated(TaskResult<Account>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismissed
		case accountCreated
		case completed
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.onboardingClient) var onboardingClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.isPresented) var isPresented
	@Dependency(\.dismiss) var dismiss

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.root, action: /Action.child .. ChildAction.root) {
				Path()
			}
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination
}

extension CreateAccountCoordinator {
	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .root(.nameAccount(.delegate(.proceed(accountName, useLedgerAsFactorSource)))):
			state.name = accountName
			state.useLedgerAsFactorSource = useLedgerAsFactorSource
			if state.useLedgerAsFactorSource {
				state.path.append(.selectLedger(.init(context: .createHardwareAccount)))
				return .none
			} else {
				return derivePublicKey(state: &state, factorSourceOption: .device)
			}

		case let .path(.element(_, action: .selectLedger(.delegate(.choseLedger(ledger))))):
			return derivePublicKey(
				state: &state,
				factorSourceOption: .specific(
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

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .createAccountResult(.success(account)):
			return .run { send in
				await send(.internal(.handleAccountCreated(TaskResult {
					try await accountsClient.saveVirtualAccount(account)
					return account
				})))
			}

		case
			let .createAccountResult(.failure(error)),
			let .handleAccountCreated(.failure(error)):
			errorQueue.schedule(error)
			state.destination = nil
			return .none

		case let .handleAccountCreated(.success(account)):
			state.destination = nil
			state.path.append(.completion(.init(
				account: account,
				config: state.config
			)))
			return .send(.delegate(.accountCreated))
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .derivePublicKey(.delegate(.derivedPublicKeys(hdKeys, factorSourceID, networkID))):
			guard let hdKey = hdKeys.first else {
				loggerGlobal.error("Failed to create account expected one single key, got: \(hdKeys.count)")
				state.destination = nil
				return .none
			}
			guard let name = state.name else {
				fatalError("Derived public keys without account name set")
			}

			return .run { send in
				await send(.internal(.createAccountResult(TaskResult {
					let factorSourceIDFromHash = try factorSourceID.extract(as: FactorSourceIDFromHash.self)

					let account = try await accountsClient.newVirtualAccount(.init(
						name: name,
						factorInstance: HierarchicalDeterministicFactorInstance(
							factorSourceId: factorSourceIDFromHash,
							publicKey: hdKey
						),
						networkID: networkID
					))

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

				})))
			}

		case .derivePublicKey(.delegate(.failedToDerivePublicKey)):
			state.destination = nil
			return .none

		case .derivePublicKey(.delegate(.cancel)):
			state.destination = nil
			return .none

		default:
			return .none
		}
	}

	private func derivePublicKey(state: inout State, factorSourceOption: DerivePublicKeys.State.FactorSourceOption) -> Effect<Action> {
		state.destination = .derivePublicKey(
			.init(
				derivationPathOption: .next(
					for: .account,
					networkID: state.config.specificNetworkID,
					curve: .curve25519,
					scheme: .cap26
				),
				factorSourceOption: factorSourceOption,
				purpose: .createNewEntity(kind: .account)
			))
		return .none
	}
}

extension CreateAccountCoordinator.State {
	public var lastStepState: CreateAccountCoordinator.Path.State? {
		path.last
	}
}
