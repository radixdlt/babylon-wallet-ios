import AccountsClient
import AddLedgerFactorSourceFeature
import Cryptography
import DerivePublicKeyFeature
import FeaturePrelude
import LedgerHardwareWalletClient
import PersonasClient

// MARK: - CreationOfEntity
public struct CreationOfEntity<Entity: EntityProtocol>: Sendable, FeatureReducer {
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
		case createEntityResult(TaskResult<Entity>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case createdEntity(Entity)
		case createEntityFailed
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			switch state.genesisFactorSourceSelection {
			case let .device(babylonDeviceFactorSource):
				return createEntityControlledByDeviceFactorSource(babylonDeviceFactorSource, state: state)
			case let .ledger(ledgers):
				precondition(ledgers.allSatisfy { $0.kind == .ledgerHQHardwareWallet })
				state.ledgers = IdentifiedArrayOf<FactorSource>.init(uniqueElements: ledgers, id: \.id)
				if let first = ledgers.first {
					state.selectedLedgerID = first.id
				}
				return .none
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .createEntityResult(.failure(error)):
			errorQueue.schedule(error)
			return .send(.delegate(.createEntityFailed))

		case let .createEntityResult(.success(entity)):
			return .send(.delegate(.createdEntity(entity)))
		}
	}
}
