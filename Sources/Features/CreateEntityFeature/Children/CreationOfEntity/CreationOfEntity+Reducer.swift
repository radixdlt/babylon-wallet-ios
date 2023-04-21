import AccountsClient
import AddLedgerFactorSourceFeature
import Cryptography
import FeaturePrelude
import LedgerHardwareWalletClient
import PersonasClient

// MARK: - GenesisFactorSourceSelection
public enum GenesisFactorSourceSelection: Sendable, Hashable {
	case device(BabylonDeviceFactorSource)
	case ledger(ledgerFactorSources: [FactorSource])
}

extension FactorSourceID {
	static let dummy = try! Self(hexCodable: .init(data: Data(repeating: 0x00, count: 32)))
}

// MARK: - CreationOfEntity
public struct CreationOfEntity<Entity: EntityProtocol>: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let networkID: NetworkID?
		public let name: NonEmptyString
		public let genesisFactorSourceSelection: GenesisFactorSourceSelection
		public var selectedLedgerID: FactorSource.ID = .dummy
		public var useLedgerAsFactorSource: Bool {
			switch genesisFactorSourceSelection {
			case .ledger: return true
			case .device: return false
			}
		}

		public var ledgers: IdentifiedArrayOf<FactorSource> = []

		@PresentationState
		public var addNewLedger: AddLedgerFactorSource.State?

		public init(
			networkID: NetworkID?,
			name: NonEmptyString,
			genesisFactorSourceSelection: GenesisFactorSourceSelection
		) {
			self.networkID = networkID
			self.name = name
			self.genesisFactorSourceSelection = genesisFactorSourceSelection
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case selectedLedger(id: FactorSource.ID)
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
				AddLedgerFactorSource()._printChanges()
			}
	}

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
		case let .selectedLedger(selectedID):
			state.selectedLedgerID = selectedID
			return .none

		case .addNewLedgerButtonTapped:
			state.addNewLedger = .init()
			return .none

		case let .confirmedLedger(ledger):
			return sendDerivePublicKeyRequest(ledger, state: state)
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case .createEntityResult(.failure):
			return .send(.delegate(.createEntityFailed))

		case let .createEntityResult(.success(entity)):
			return .send(.delegate(.createdEntity(entity)))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .addNewLedger(.presented(.delegate(.completed(ledger)))):
			state.addNewLedger = nil
			state.selectedLedgerID = ledger.id
			state.ledgers[id: ledger.id] = ledger
			return .none

		default:
			return .none
		}
	}
}

extension CreationOfEntity {
	private func sendDerivePublicKeyRequest(
		_ ledger: FactorSource,
		state: State
	) -> EffectTask<Action> {
		let entityKind = Entity.entityKind

		let request = try! CreateVirtualEntityControlledByLedgerFactorSourceRequest(
			networkID: state.networkID,
			ledger: ledger,
			displayName: state.name,
			extraProperties: { numberOfEntities in
				switch entityKind {
				case .identity: return .forPersona(.init(fields: []))
				case .account: return .forAccount(.init(numberOfAccountsOnNetwork: numberOfEntities))
				}
			},
			derivePublicKey: { derivationPath in
				try await ledgerHardwareWalletClient.deriveCurve25519PublicKey(derivationPath, ledger)
			}
		)

		return .run { send in
			await send(.internal(
				.createEntityResult(
					TaskResult {
						let entity: Entity = try await {
							switch entityKind {
							case .account:
								let account = try await accountsClient.newUnsavedVirtualAccountControlledByLedgerFactorSource(request)
								try await accountsClient.saveVirtualAccount(.init(
									account: account,
									shouldUpdateFactorSourceNextDerivationIndex: true
								))
								return try account.cast()
							case .identity:
								let persona = try await personasClient.newUnsavedVirtualPersonaControlledByLedgerFactorSource(request)
								try await personasClient.saveVirtualPersona(persona)
								return try persona.cast()
							}
						}()
						return entity
					}
				)
			))
		}
	}

	private func createEntityControlledByDeviceFactorSource(
		_ babylonFactorSource: BabylonDeviceFactorSource,
		state: State
	) -> EffectTask<Action> {
		let entityKind = Entity.entityKind

		let request = CreateVirtualEntityControlledByDeviceFactorSourceRequest(
			networkID: state.networkID,
			babylonDeviceFactorSource: babylonFactorSource,
			displayName: state.name,
			extraProperties: { numberOfEntities in
				switch entityKind {
				case .identity: return .forPersona(.init(fields: []))
				case .account: return .forAccount(.init(numberOfAccountsOnNetwork: numberOfEntities))
				}
			}
		)

		return .run { send in
			await send(.internal(.createEntityResult(TaskResult {
				switch entityKind {
				case .account:
					let account = try await accountsClient.newUnsavedVirtualAccountControlledByDeviceFactorSource(request)
					try await accountsClient.saveVirtualAccount(.init(
						account: account,
						shouldUpdateFactorSourceNextDerivationIndex: true
					))
					return try account.cast()
				case .identity:
					let persona = try await personasClient.newUnsavedVirtualPersonaControlledByDeviceFactorSource(request)
					try await personasClient.saveVirtualPersona(persona)
					return try persona.cast()
				}
			}
			)))
		}
	}
}
