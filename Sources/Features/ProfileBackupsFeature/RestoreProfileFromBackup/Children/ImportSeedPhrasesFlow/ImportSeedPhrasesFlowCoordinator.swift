import Cryptography
import DeviceFactorSourceClient
import FeaturePrelude

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
		public init(profileSnapshot: ProfileSnapshot) {
			self.profileSnapshot = profileSnapshot
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum InternalAction: Sendable, Equatable {
		case loadControlledEntities(TaskResult<IdentifiedArrayOf<EntitiesControlledByFactorSource>>)
	}

	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	@Dependency(\.errorQueue) var errorQueue
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
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
			return .none
		}
	}
}

/*
 private func showImportMnemonic(state: inout State) {
     state.destination = .importMnemonic(.init(
         isWordCountFixed: true,
         persistAsMnemonicKind: .intoKeychainOnly,
         wordCount: .twentyFour
     ))
 }
 */

/*
 case let .destination(.presented(.importMnemonic(.delegate(.notSavedInProfile(factorSource))))):
     guard let importedContent = state.importedContent else {
         assertionFailure("Imported mnemonic, but didn't import neither a snapshot or a profile header")
         return .none
     }
     loggerGlobal.notice("Starting import snapshot process...")
     return .run { [importedContent] send in
         switch importedContent {
         case let .left(snapshot):
             loggerGlobal.notice("Importing snapshot...")
             try await backupsClient.importProfileSnapshot(snapshot, factorSource.id)
         case let .right(header):
             try await backupsClient.importCloudProfile(header, factorSource.id)
         }
         await send(.delegate(.profileImported))
     } catch: { error, _ in
         errorQueue.schedule(error)
     }

 */
