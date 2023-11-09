#if DEBUG

// MARK: - DebugKeychainContents
public struct DebugKeychainContents: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var keyedMnemonics: IdentifiedArrayOf<KeyedMnemonicWithPassphrase> = []
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case deleteMnemonicByFactorSourceID(FactorSourceID.FromHash)
		case deleteAllMnemonics
	}

	@Dependency(\.secureStorageClient) var secureStorageClient
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			loadKeyValues(into: &state)
			return .none

		case let .deleteMnemonicByFactorSourceID(id):
			return delete(ids: [id])

		case .deleteAllMnemonics:
			return delete(ids: state.keyedMnemonics.elements.map(\.id))
		}
	}

	private func delete(ids: [FactorSourceID.FromHash]) -> Effect<Action> {
		.run { _ in
			for id in ids {
				try secureStorageClient.deleteMnemonicByFactorSourceID(id)
			}
		} catch: { error, _ in
			loggerGlobal.error("Failed to delete mnemonic: \(error)")
		}
	}

	private func loadKeyValues(into state: inout State) {
		state.keyedMnemonics = secureStorageClient.getAllMnemonics().asIdentifiable()
	}
}

extension KeyedMnemonicWithPassphrase: Identifiable {
	public typealias ID = FactorSourceID.FromHash
	public var id: ID {
		factorSourceID
	}
}
#endif // DEBUG
