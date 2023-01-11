import ComposableArchitecture
import Cryptography
import ErrorQueue
import Prelude
import Profile
import SwiftUI

// MARK: - ImportMnemonic
public struct ImportMnemonic: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.mnemonicImporter) var mnemonicImporter
	@Dependency(\.profileFromSnapshotImporter) var profileFromSnapshotImporter
	public init() {}
}

public extension ImportMnemonic {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
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
			errorQueue.schedule(error)
			return .none

		case .internal(.view(.saveImportedMnemonicButtonTapped)):
			guard let mnemonic = state.importedMnemonic else {
				return .none
			}
			return .run { [
				factorSourceReference = state.importedProfileSnapshot.factorSources.curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources.first.reference
			] send in
				await send(
					.internal(
						.system(
							.saveImportedMnemonicResult(
								TaskResult(catching: {
									try await keychainClient.updateFactorSource(
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
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.saveImportedMnemonicResult(.success(mnemonic)))):
			state.savedMnemonic = mnemonic
			return .none

		case .internal(.view(.importProfileFromSnapshotButtonTapped)):
			return .run { [snapshot = state.importedProfileSnapshot] send in
				await send(.internal(.system(.profileFromSnapshotResult(TaskResult {
					try profileFromSnapshotImporter(snapshot)
				}))))
			}

		case let .internal(.system(.profileFromSnapshotResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.profileFromSnapshotResult(.success(profile)))):
			guard let mnemonic = state.savedMnemonic else {
				struct ExpectedMnemonicError: LocalizedError {
					let errorDescription: String? = "Expected to have saved mnemonic."
				}
				errorQueue.schedule(ExpectedMnemonicError())
				return .none
			}
			return .run { send in
				await send(.delegate(.finishedImporting(mnemonic: mnemonic, andProfile: profile)))
			}

		case .delegate:
			return .none
		}
	}
}
