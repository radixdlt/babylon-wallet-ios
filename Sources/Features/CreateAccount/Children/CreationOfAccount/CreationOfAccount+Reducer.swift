import AccountsClient
import AddLedgerFactorSourceFeature
import Cryptography
import DerivePublicKeyFeature
import FeaturePrelude
import LedgerHardwareWalletClient

public struct CreationOfAccount: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let name: NonEmptyString
		public var derivePublicKey: DerivePublicKey.State

		public init(
			name: NonEmptyString,
			derivePublicKey: DerivePublicKey.State
		) {
			self.name = name
			self.derivePublicKey = derivePublicKey
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case createAccountResult(TaskResult<Profile.Network.Account>)
	}

	public enum ChildAction: Sendable, Equatable {
		case derivePublicKey(DerivePublicKey.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case createdAccount(Profile.Network.Account)
		case createAccountFailed
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.derivePublicKey, action: /Action.child .. ChildAction.derivePublicKey) {
			DerivePublicKey()
		}

		Reduce(core)
	}

//	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
//		switch viewAction {
//		case .appeared:
//			switch state.genesisFactorSourceSelection {
//			case let .device(babylonDeviceFactorSource):
//				return createEntityControlledByDeviceFactorSource(babylonDeviceFactorSource, state: state)
//			case let .ledger(ledgers):
//				precondition(ledgers.allSatisfy { $0.kind == .ledgerHQHardwareWallet })
//				state.ledgers = IdentifiedArrayOf<FactorSource>.init(uniqueElements: ledgers, id: \.id)
//				if let first = ledgers.first {
//					state.selectedLedgerID = first.id
//				}
//				return .none
//			}
//		}
//	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .createAccountResult(.failure(error)):
			errorQueue.schedule(error)
			return .send(.delegate(.createAccountFailed))

		case let .createAccountResult(.success(account)):
			return .send(.delegate(.createdAccount(account)))
		}
	}
}
