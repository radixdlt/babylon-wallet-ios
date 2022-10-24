import ComposableArchitecture
import Foundation
import Mnemonic
import Profile

// MARK: - ImportMnemonic.Action
public extension ImportMnemonic {
	enum Action: Equatable {
		case coordinate(CoordinateAction)
		case `internal`(InternalAction)
	}
}

public extension ImportMnemonic {
	enum CoordinateAction: Equatable {
		case goBack
		case finishedImporting(mnemonic: Mnemonic, andProfile: Profile)
		case failedToImportMnemonicOrProfile(reason: String)
	}

	enum InternalAction: Equatable {
		case goBack
		case phraseOfMnemonicToImportChanged(String)
		case importMnemonic
		case importMnemonicResult(TaskResult<Mnemonic>)
		case saveImportedMnemonic
		case saveImportedMnemonicResult(TaskResult<Mnemonic>)

		case importProfileFromSnapshot
		case profileFromSnapshotResult(TaskResult<Profile>)
	}
}
