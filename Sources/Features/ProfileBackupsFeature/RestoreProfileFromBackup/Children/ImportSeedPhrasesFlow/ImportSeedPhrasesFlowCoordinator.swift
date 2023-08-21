import Cryptography
import DeviceFactorSourceClient
import FeaturePrelude
import ImportMnemonicFeature

// MARK: - MnemonicToImport
public struct MnemonicToImport: Sendable, Hashable {
	public let factorSourceID: FactorSourceID.FromHash
	public let mnemonicWordCount: BIP39.WordCount

	/// As it currently stands we only ever have one "Babylon" `.device` factor source, and it is required
	/// to be imported, any imported "Olympia" `device` factor source will be skippable.
	public let isSkippable: Bool

	public let controllingAccounts: [Profile.Network.Account]
	public let controllingPersonas: [Profile.Network.Persona]

	init(
		factorSourceID: FactorSourceID.FromHash,
		isSkippable: Bool,
		mnemonicWordCount: BIP39.WordCount,
		controllingAccounts: [Profile.Network.Account],
		controllingPersonas: [Profile.Network.Persona]
	) {
		self.factorSourceID = factorSourceID
		self.isSkippable = isSkippable
		self.mnemonicWordCount = mnemonicWordCount
		self.controllingAccounts = controllingAccounts
		self.controllingPersonas = controllingPersonas
	}

	init(entitiesControlledByFactorSource: EntitiesControlledByFactorSource) {
		self.init(
			factorSourceID: entitiesControlledByFactorSource.deviceFactorSource.id,
			isSkippable: entitiesControlledByFactorSource.deviceFactorSource.supportsOlympia,
			mnemonicWordCount: entitiesControlledByFactorSource.deviceFactorSource.hint.mnemonicWordCount,
			controllingAccounts: entitiesControlledByFactorSource.accounts,
			controllingPersonas: entitiesControlledByFactorSource.personas
		)
	}
}

// MARK: - ImportMnemonicsFlowCoordinator
public struct ImportMnemonicsFlowCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var mnemonicsLeftToImport: OrderedSet<MnemonicToImport> = []
		public let profileSnapshot: ProfileSnapshot
		public var importingMnemonic: ImportMnemonic.State?
		public init(profileSnapshot: ProfileSnapshot) {
			self.profileSnapshot = profileSnapshot
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case importingMnemonic(ImportMnemonic.Action)
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
	}

	public enum InternalAction: Sendable, Equatable {
		case loadControlledEntities(TaskResult<IdentifiedArrayOf<EntitiesControlledByFactorSource>>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case finishedImportingMnemonics
	}

	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	@Dependency(\.errorQueue) var errorQueue
	public init() {}

	public var body: some ReducerProtocolOf<ImportMnemonicsFlowCoordinator> {
		Reduce(core)
			.ifLet(\.importingMnemonic, action: /Action.child .. ChildAction.importingMnemonic) {
				ImportMnemonic()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .onFirstTask:
			return .task { [snapshot = state.profileSnapshot] in
				await .internal(.loadControlledEntities(TaskResult {
					try await deviceFactorSourceClient.controlledEntities(snapshot)
				}))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadControlledEntities(.failure(error)):
			// FIXME: Error handling...?
			loggerGlobal.error("Failed to load entities controlled by profile snapshot")
			errorQueue.schedule(error)
			return .none

		case let .loadControlledEntities(.success(factorSourcesControllingEntities)):
			state.mnemonicsLeftToImport = .init(
				uncheckedUniqueElements: factorSourcesControllingEntities
					.map(MnemonicToImport.init(entitiesControlledByFactorSource:))
			)
			return nextMnemonicIfNeeded(state: &state)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .importingMnemonic(.delegate(.persistedMnemonicInKeychainOnly(_, factorSourceID))):

			state.mnemonicsLeftToImport.removeAll(where: { $0.factorSourceID == factorSourceID })
			return nextMnemonicIfNeeded(state: &state)

		case .importingMnemonic(.delegate(.persistedNewFactorSourceInProfile(_))), .importingMnemonic(.delegate(.doneViewing)):
			preconditionFailure("Incorrect impl")
			return .none

		default:
			return .none
		}
	}

	private func nextMnemonicIfNeeded(state: inout State) -> EffectTask<Action> {
		if let next = state.mnemonicsLeftToImport.first {
			state.importingMnemonic = .init(
				isWordCountFixed: true,
				persistStrategy: .intoKeychainOnly,
				mnemonicForFactorSourceKind: next.mnemonicWordCount == .twelve ? .onDevice(.olympia) : .onDevice(.babylon)
			)
			return .none
		} else {
			return .send(.delegate(.finishedImportingMnemonics))
		}
	}
}
