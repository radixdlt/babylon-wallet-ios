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

		@PresentationState
		public var addNewLedger: AddLedgerFactorSource.State?

		public init(
			name: NonEmptyString,
			derivePublicKey: DerivePublicKey.State
		) {
			self.name = name
			self.derivePublicKey = derivePublicKey
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case selectedLedger(id: FactorSource.ID?)
		case addNewLedgerButtonTapped
		case confirmedLedger(FactorSource)
	}

	public enum ChildAction: Sendable, Equatable {
		case addNewLedger(PresentationAction<AddLedgerFactorSource.Action>)
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

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$addNewLedger, action: /Action.child .. ChildAction.addNewLedger) {
				AddLedgerFactorSource()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
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
//		case let .selectedLedger(selectedID):
//			state.selectedLedgerID = selectedID
//			return .none
//
//		case .addNewLedgerButtonTapped:
//			state.addNewLedger = .init()
//			return .none
//
//		case let .confirmedLedger(ledger):
//			return sendDerivePublicKeyRequest(ledger, state: state)
//		}
		fatalError()
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
//		switch internalAction {
//		case let .createEntityResult(.failure(error)):
//			errorQueue.schedule(error)
//			return .send(.delegate(.createEntityFailed))
//
//		case let .createEntityResult(.success(entity)):
//			return .send(.delegate(.createdEntity(entity)))
//		}
		fatalError()
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
//		switch childAction {
//		case let .addNewLedger(.presented(.delegate(.completed(ledger)))):
//			state.addNewLedger = nil
//			state.selectedLedgerID = ledger.id
//			state.ledgers[id: ledger.id] = ledger
//			return .none
//
//		default:
//			return .none
//		}
		fatalError()
	}
}

// extension CreationOfEntity.State {
//	public var useLedgerAsFactorSource: Bool {
//		switch genesisFactorSourceSelection {
//		case .ledger: return true
//		case .device: return false
//		}
//	}
// }
