import ComposableArchitecture
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

		public init(
			root: Path.State? = nil,
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
			switch path.last {
			case .step1_nameAccount, .step2_selectLedger:
				return true
			case .step3_completion:
				return false
			case .none:
				return true
			}
		}
	}

	public struct Path: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case step1_nameAccount(NameAccount.State)
			case step2_selectLedger(LedgerHardwareDevices.State)
			case step3_completion(NewAccountCompletion.State)
		}

		public enum Action: Sendable, Equatable {
			case step1_nameAccount(NameAccount.Action)
			case step2_selectLedger(LedgerHardwareDevices.Action)
			case step3_completion(NewAccountCompletion.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.step1_nameAccount, action: /Action.step1_nameAccount) {
				NameAccount()
			}
			Scope(state: /State.step2_selectLedger, action: /Action.step2_selectLedger) {
				LedgerHardwareDevices()
			}
			Scope(state: /State.step3_completion, action: /Action.step3_completion) {
				NewAccountCompletion()
			}
		}
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case derivePublicKeys(DerivePublicKeys.State)
		}

		public enum Action: Sendable, Hashable {
			case derivePublicKeys(DerivePublicKeys.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.derivePublicKeys, action: /Action.derivePublicKeys) {
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
		case derivePublicKeysFromDevice
		case derivePublicKeysFromLedger(LedgerHardwareWalletFactorSource)
		case createAccountResult(TaskResult<Profile.Network.Account>)
		case handleAccountCreated(Profile.Network.Account)
		case handleFailure
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismissed
		case completed
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.accountsClient) var accountsClient
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
			assert(state.config.canBeDismissed)
			return .run { send in
				await send(.delegate(.dismissed))
				if isPresented {
					await dismiss()
				}
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .root(.step1_nameAccount(.delegate(.proceed(accountName, useLedgerAsFactorSource)))):
			state.name = accountName
			if useLedgerAsFactorSource {
				state.path.append(.step2_selectLedger(.init(context: .createHardwareAccount)))
				return .none
			} else {
				return .send(.internal(.derivePublicKeysFromDevice))
			}

		case let .path(.element(_, action: .step2_selectLedger(.delegate(.choseLedger(ledger))))):
			return .send(.internal(.derivePublicKeysFromLedger(ledger)))

		case .path(.element(_, action: .step3_completion(.delegate(.completed)))):
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
		case .derivePublicKeysFromDevice:
			state.destination = .derivePublicKeys(
				.init(
					derivationPathOption: .next(
						for: .account,
						networkID: state.config.specificNetworkID,
						curve: .curve25519,
						scheme: .cap26
					),
					factorSourceOption: .device,
					purpose: .createNewEntity(kind: .account)
				))
			return .none

		case let .derivePublicKeysFromLedger(ledger):
			state.destination = .derivePublicKeys(
				.init(
					derivationPathOption: .next(
						for: .account,
						networkID: state.config.specificNetworkID,
						curve: .curve25519,
						scheme: .cap26
					),
					factorSourceOption: .specific(ledger.embed()),
					purpose: .createNewEntity(kind: .account)
				))
			return .none

		case let .createAccountResult(.failure(error)):
			errorQueue.schedule(error)
			state.destination = nil
			return .none

		case let .createAccountResult(.success(account)):
			return .run { send in
				try await accountsClient.saveVirtualAccount(account)
				await send(.internal(.handleAccountCreated(account)))
			} catch: { error, send in
				loggerGlobal.error("Failed to save newly created virtual account into profile: \(error)")
				await send(.internal(.handleFailure))
			}

		case let .handleAccountCreated(account):
			state.destination = nil
			state.path.append(.step3_completion(.init(
				account: account,
				config: state.config
			)))
			return .none

		case .handleFailure:
			state.destination = nil
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .derivePublicKeys(.delegate(.derivedPublicKeys(hdKeys, factorSourceID, networkID))):
			guard let hdKey = hdKeys.first else {
				loggerGlobal.error("Failed to create account expected one single key, got: \(hdKeys.count)")
				return .send(.internal(.handleFailure))
			}
			guard let name = state.name else {
				fatalError("Derived public keys without account name set")
			}

			return .run { send in
				await send(.internal(.createAccountResult(TaskResult {
					let account = try await accountsClient.newVirtualAccount(.init(
						name: name,
						factorInstance: .init(
							factorSourceID: factorSourceID,
							publicKey: hdKey.publicKey,
							derivationPath: hdKey.derivationPath
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

		case .derivePublicKeys(.delegate(.failedToDerivePublicKey)):
			return .send(.internal(.handleFailure))

		default:
			return .none
		}
	}
}

extension CreateAccountCoordinator.State {
	public var lastStepState: CreateAccountCoordinator.Path.State? {
		path.last
	}
}
