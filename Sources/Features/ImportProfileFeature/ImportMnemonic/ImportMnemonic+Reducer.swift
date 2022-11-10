import ComposableArchitecture
import Foundation
import Mnemonic
import Profile
import SwiftUI

// MARK: - ImportMnemonic
public struct ImportMnemonic: ReducerProtocol {
	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.mnemonicImporter) var mnemonicImporter
	@Dependency(\.profileFromSnapshotImporter) var profileFromSnapshotImporter
	public init() {}
}

// MARK: ReducerProtocol Conformance
public extension ImportMnemonic {
	func reduce(into state: inout State, action: Action) -> Effect<Action, Never> {
		switch action {
		case .internal(.view(.goBackButtonTapped)):
			return .run { send in
				await send(.delegate(.goBack))
			}

		case let .internal(.view(.phraseOfMnemonicToImportChanged(phraseOfMnemonicToImport))):
			state.phraseOfMnemonicToImport = phraseOfMnemonicToImport
			return .none

		case .internal(.view(.importMnemonicButtonTapped)):
			return .run { [mnemonicImporter, phrase = state.phraseOfMnemonicToImport] send in
				await send(.internal(.system(.importMnemonicResult(TaskResult { try mnemonicImporter(phrase) }))))
			}

		case let .internal(.system(.importMnemonicResult(.success(mnemonicToSave)))):
			state.importedMnemonic = mnemonicToSave
			return .none

		case let .internal(.system(.importMnemonicResult(.failure(error)))):
			return .run { send in
				await send(.delegate(.failedToImportMnemonicOrProfile(reason: "Failed to import mnemonic, error: \(String(describing: error))")))
			}

		case .internal(.view(.saveImportedMnemonicButtonTapped)):
			guard let mnemonic = state.importedMnemonic else {
				return .none
			}
			return .run { [
				keychainClient,
				factorSourceReference = state.importedProfileSnapshot.factorSources.curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources.first.reference
			] send in
				await send(
					.internal(
						.system(
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
				)
			}

		case let .internal(.system(.saveImportedMnemonicResult(.failure(error)))):
			return .run { send in
				await send(.delegate(.failedToImportMnemonicOrProfile(reason: "Failed to save mnemonic to keychain, error: \(String(describing: error))")))
			}

		case let .internal(.system(.saveImportedMnemonicResult(.success(mnemonic)))):
			state.savedMnemonic = mnemonic
			return .none

		case .internal(.view(.importProfileFromSnapshotButtonTapped)):
			return .run { [profileFromSnapshotImporter, snapshot = state.importedProfileSnapshot] send in
				await send(.internal(.system(.profileFromSnapshotResult(TaskResult {
					try profileFromSnapshotImporter(snapshot)
				}))))
			}

		case let .internal(.system(.profileFromSnapshotResult(.failure(error)))):
			return .run { send in
				await send(.delegate(.failedToImportMnemonicOrProfile(reason: "Failed to import profile from snapshot, error: \(String(describing: error))")))
			}

		case let .internal(.system(.profileFromSnapshotResult(.success(profile)))):
			guard let mnemonic = state.savedMnemonic else {
				return .run { send in
					await send(.delegate(.failedToImportMnemonicOrProfile(reason: "Expected to have saved mnemonic.")))
				}
			}
			return .run { send in
				await send(.delegate(.finishedImporting(mnemonic: mnemonic, andProfile: profile)))
			}

		case .delegate:
			return .none
		}
	}
}
