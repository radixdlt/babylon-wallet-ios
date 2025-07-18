#if DEBUG
import Sargon

// MARK: - DebugKeychainContents
struct DebugKeychainContents: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var keyedMnemonics: IdentifiedArrayOf<KeyedMnemonicWithMetadata> = []
		init() {}
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case deleteMnemonicByFactorSourceID(FactorSourceIDFromHash)
		case deleteAllMnemonics
	}

	enum InternalAction: Sendable, Equatable {
		case loadedMnemonics([KeyedMnemonicWithMetadata])
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			loadKeyValues()

		case let .deleteMnemonicByFactorSourceID(id):
			delete(ids: [id])

		case .deleteAllMnemonics:
			delete(ids: state.keyedMnemonics.map(\.id))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedMnemonics(mnemonics):
			state.keyedMnemonics = mnemonics.asIdentified()
			return .none
		}
	}

	private func delete(ids: [FactorSourceIDFromHash]) -> Effect<Action> {
		.run { _ in
			for id in ids {
				try secureStorageClient.deleteMnemonicByFactorSourceID(id)
			}
		} catch: { error, _ in
			loggerGlobal.error("Failed to delete mnemonic: \(error)")
		}.merge(with: loadKeyValues())
	}

	private func loadKeyValues() -> Effect<Action> {
		.run { send in
			let keyedMnemonics = secureStorageClient.getAllMnemonics()

			let values = try await keyedMnemonics.asyncMap {
				do {
//					if
//						let deviceFactorSource = try await factorSourcesClient.getFactorSource(
//							id: $0.factorSourceID.asGeneral,
//							as: DeviceFactorSource.self
//						),
//						let entitiesControlledByFactorSource = nil //try? await deviceFactorSourceClient.entitiesControlledByFactorSource(deviceFactorSource, nil)
//					{
//						return KeyedMnemonicWithMetadata(keyedMnemonic: $0, entitiesControlledByFactorSource: entitiesControlledByFactorSource)
//					} else {
					return KeyedMnemonicWithMetadata(keyedMnemonic: $0)
//					}
				} catch {
					return KeyedMnemonicWithMetadata(keyedMnemonic: $0)
				}
			}

			await send(.internal(.loadedMnemonics(values)))
		}
	}
}

struct KeyedMnemonicWithMetadata: Sendable, Hashable, Identifiable {
	let keyedMnemonic: KeyedMnemonicWithPassphrase
	typealias ID = FactorSourceIDFromHash
	var id: ID { keyedMnemonic.factorSourceID }
	let entitiesControlledByFactorSource: EntitiesControlledByFactorSource?
	init(keyedMnemonic: KeyedMnemonicWithPassphrase, entitiesControlledByFactorSource: EntitiesControlledByFactorSource? = nil) {
		self.keyedMnemonic = keyedMnemonic
		self.entitiesControlledByFactorSource = entitiesControlledByFactorSource
	}
}
#endif // DEBUG
