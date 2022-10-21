import ComposableArchitecture
import Foundation
import Mnemonic
import Profile
import SwiftUI

public typealias MnemonicImporter = (String) throws -> Mnemonic

// MARK: - MnemonicImporterKey
private enum MnemonicImporterKey: DependencyKey {
	typealias Value = MnemonicImporter
	static let liveValue = { try Mnemonic(phrase: $0, language: nil) }
}

public extension DependencyValues {
	var mnemonicImporter: MnemonicImporter {
		get { self[MnemonicImporterKey.self] }
		set { self[MnemonicImporterKey.self] = newValue }
	}
}

public typealias ProfileFromSnapshotImporter = (ProfileSnapshot) throws -> Profile

// MARK: - ProfileFromSnapshotImporterKey
private enum ProfileFromSnapshotImporterKey: DependencyKey {
	typealias Value = ProfileFromSnapshotImporter
	static let liveValue = { try Profile(snapshot: $0) }
}

public extension DependencyValues {
	var profileFromSnapshotImporter: ProfileFromSnapshotImporter {
		get { self[ProfileFromSnapshotImporterKey.self] }
		set { self[ProfileFromSnapshotImporterKey.self] = newValue }
	}
}

// MARK: - ImportMnemonic
public struct ImportMnemonic: ReducerProtocol {
	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.mnemonicImporter) var mnemonicImporter
	@Dependency(\.profileFromSnapshotImporter) var profileFromSnapshotImporter
	public init() {}
}

// MARK: ImportMnemonic.State
public extension ImportMnemonic {
	struct State: Equatable {
		public var importedProfileSnapshot: ProfileSnapshot
		public var phraseOfMnemonicToImport: String
		public var importedMnemonic: Mnemonic?
		public var savedMnemonic: Mnemonic?

		init(
			importedProfileSnapshot: ProfileSnapshot,
			phraseOfMnemonicToImport: String = "bright club bacon dinner achieve pull grid save ramp cereal blush woman humble limb repeat video sudden possible story mask neutral prize goose mandate"
		) {
			self.importedProfileSnapshot = importedProfileSnapshot
			self.phraseOfMnemonicToImport = phraseOfMnemonicToImport
		}
	}
}

// MARK: ImportMnemonic.Action
public extension ImportMnemonic {
	enum Action: Equatable {
		case coordinate(CoordinateAction)
		case `internal`(InternalAction)
	}
}

public extension ImportMnemonic {
	enum CoordinateAction: Equatable {
		case finishedImporting(mnemonic: Mnemonic, andProfile: Profile)
		case failedToImportMnemonicOrProfile(reason: String)
	}

	enum InternalAction: Equatable {
		case phraseOfMnemonicToImportChanged(String)
		case importMnemonicButtonPressed
		case importMnemonicResult(TaskResult<Mnemonic>)
		case saveImportedMnemonicButtonPressed
		case saveImportedMnemonicResult(TaskResult<Mnemonic>)

		case importProfileFromSnapshotButtonPressed
		case profileFromSnapshotResult(TaskResult<Profile>)
	}
}

public extension ImportMnemonic {
	func reduce(into state: inout State, action: Action) -> Effect<Action, Never> {
		switch action {
		case .coordinate:
			return .none
		case let .internal(.phraseOfMnemonicToImportChanged(phraseOfMnemonicToImport)):
			state.phraseOfMnemonicToImport = phraseOfMnemonicToImport
			return .none
		case .internal(.importMnemonicButtonPressed):
			return .run { [mnemonicImporter, phrase = state.phraseOfMnemonicToImport] send in
				await send(.internal(.importMnemonicResult(TaskResult { try mnemonicImporter(phrase) })))
			}
		case let .internal(.importMnemonicResult(.success(mnemonicToSave))):
			state.importedMnemonic = mnemonicToSave
			return .none
		case let .internal(.importMnemonicResult(.failure(error))):
			return .run { send in
				await send(.coordinate(.failedToImportMnemonicOrProfile(reason: "Failed to import mnemonic, error: \(String(describing: error))")))
			}

		case .internal(.saveImportedMnemonicButtonPressed):
			guard let mnemonic = state.importedMnemonic else {
				return .none
			}
			return .run { [
				keychainClient,
				factorSourceReference = state.importedProfileSnapshot.factorSources.curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources.first.reference
			] send in
				await send(
					.internal(
						.saveImportedMnemonicResult(
							TaskResult(catching: {
								try keychainClient.saveFactorSource(
									mnemonic: mnemonic,
									reference: factorSourceReference
								)
							}).map { mnemonic }
						)
					)
				)
			}
		case let .internal(.saveImportedMnemonicResult(.failure(error))):
			return .run { send in
				await send(.coordinate(.failedToImportMnemonicOrProfile(reason: "Failed to save mnemonic to keychain, error: \(String(describing: error))")))
			}
		case let .internal(.saveImportedMnemonicResult(.success(mnemonic))):
			state.savedMnemonic = mnemonic
			return .none

		case .internal(.importProfileFromSnapshotButtonPressed):
			return .run { [profileFromSnapshotImporter, snapshot = state.importedProfileSnapshot] send in
				await send(.internal(.profileFromSnapshotResult(TaskResult {
					try profileFromSnapshotImporter(snapshot)
				})))
			}
		case let .internal(.profileFromSnapshotResult(.failure(error))):
			return .run { send in
				await send(.coordinate(.failedToImportMnemonicOrProfile(reason: "Failed to import profile from snapshot, error: \(String(describing: error))")))
			}
		case let .internal(.profileFromSnapshotResult(.success(profile))):
			guard let mnemonic = state.savedMnemonic else {
				return .run { send in
					await send(.coordinate(.failedToImportMnemonicOrProfile(reason: "Expected to have saved mnemonic.")))
				}
			}
			return .run { send in
				await send(.coordinate(.finishedImporting(mnemonic: mnemonic, andProfile: profile)))
			}
		}
	}
}

// MARK: ImportMnemonic.View
public extension ImportMnemonic {
	struct View: SwiftUI.View {
		let store: StoreOf<ImportMnemonic>
		public init(store: StoreOf<ImportMnemonic>) {
			self.store = store
		}
	}
}

public extension ImportMnemonic.View {
	var body: some View {
		WithViewStore(store, observe: { $0 }) { viewStore in
			VStack {
				TextField(
					"Mnemonic phrasec",
					text: viewStore.binding(
						get: \.phraseOfMnemonicToImport,
						send: { ImportMnemonic.Action.internal(.phraseOfMnemonicToImportChanged($0)) }
					)
				)
				Button("Import mnemonic") {
					viewStore.send(.internal(.importMnemonicButtonPressed))
				}
				.disabled(viewStore.phraseOfMnemonicToImport.isEmpty)

				Button("Save imported mnemonic") {
					viewStore.send(.internal(.saveImportedMnemonicButtonPressed))
				}
				.disabled(viewStore.importedMnemonic == nil)

				Button("Profile from snapshot") {
					viewStore.send(.internal(.importProfileFromSnapshotButtonPressed))
				}
				.disabled(viewStore.savedMnemonic == nil)
			}
		}
	}
}
