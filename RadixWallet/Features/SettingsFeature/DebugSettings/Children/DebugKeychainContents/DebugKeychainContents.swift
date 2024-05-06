#if DEBUG
import Sargon

// MARK: - DebugKeychainContents
public struct DebugKeychainContents: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var keyedMnemonics: IdentifiedArrayOf<KeyedMnemonicWithMetadata> = []
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case deleteUserInfo
		case createAndSaveUserInfoWithRust
		case createAndSaveUserInfoWithSwift
		case deleteMnemonicByFactorSourceID(FactorSourceIDFromHash)
		case deleteAllMnemonics
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedMnemonics([KeyedMnemonicWithMetadata])
	}

	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return loadKeyValues()

		case let .deleteMnemonicByFactorSourceID(id):
			return delete(ids: [id])

		case .deleteAllMnemonics:
			return delete(ids: state.keyedMnemonics.map(\.id))

		case .createAndSaveUserInfoWithRust:
			overlayWindowClient.scheduleHUD(.init(text: "Saving NEW UserInfo created from Rust Sargon"))
			try! secureStorageClient.saveDeviceInfo(DeviceInfo.sample)
			return .none

		case .createAndSaveUserInfoWithSwift:
			overlayWindowClient.scheduleHUD(.init(text: "Saving NEW UserInfo created with Swift"))
			try! secureStorageClient.saveDeviceInfo(DeviceInfo(id: .init(), date: .now, description: "Debug keychain test"))
			return .none

		case .deleteUserInfo:
			overlayWindowClient.scheduleHUD(.init(text: "Deleting UserInfo"))
			try? keychainClient.removeData(forKey: deviceInfoKey)
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
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
					if
						let deviceFactorSource = try await factorSourcesClient.getFactorSource(
							id: $0.factorSourceID.asGeneral,
							as: DeviceFactorSource.self
						),
						let entitiesControlledByFactorSource = try? await deviceFactorSourceClient.entitiesControlledByFactorSource(deviceFactorSource, nil)
					{
						return KeyedMnemonicWithMetadata(keyedMnemonic: $0, entitiesControlledByFactorSource: entitiesControlledByFactorSource)
					} else {
						return KeyedMnemonicWithMetadata(keyedMnemonic: $0)
					}
				} catch {
					return KeyedMnemonicWithMetadata(keyedMnemonic: $0)
				}
			}

			await send(.internal(.loadedMnemonics(values)))
		}
	}
}

public struct KeyedMnemonicWithMetadata: Sendable, Hashable, Identifiable {
	public let keyedMnemonic: KeyedMnemonicWithPassphrase
	public typealias ID = FactorSourceIDFromHash
	public var id: ID { keyedMnemonic.factorSourceID }
	public let entitiesControlledByFactorSource: EntitiesControlledByFactorSource?
	init(keyedMnemonic: KeyedMnemonicWithPassphrase, entitiesControlledByFactorSource: EntitiesControlledByFactorSource? = nil) {
		self.keyedMnemonic = keyedMnemonic
		self.entitiesControlledByFactorSource = entitiesControlledByFactorSource
	}
}
#endif // DEBUG
