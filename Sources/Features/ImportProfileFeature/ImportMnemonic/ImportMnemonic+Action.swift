import ComposableArchitecture
import Foundation
import Mnemonic
import Profile

// MARK: - ImportMnemonic.Action
public extension ImportMnemonic {
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

public extension ImportMnemonic.Action {
	enum ViewAction: Equatable {
		case goBackButtonTapped
		case importMnemonicButtonTapped
		case importProfileFromSnapshotButtonTapped
		case saveImportedMnemonicButtonTapped
		case phraseOfMnemonicToImportChanged(String)
	}
}

// MARK: - ImportMnemonic.InternalAction
public extension ImportMnemonic.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

public extension ImportMnemonic.Action {
	enum SystemAction: Equatable {
		case importMnemonicResult(TaskResult<Mnemonic>)
		case saveImportedMnemonicResult(TaskResult<Mnemonic>)
		case profileFromSnapshotResult(TaskResult<Profile>)
	}
}

// MARK: - ImportMnemonic.DelegateAction
public extension ImportMnemonic.Action {
	enum DelegateAction: Equatable {
		case goBack
		case finishedImporting(mnemonic: Mnemonic, andProfile: Profile)
		case failedToImportMnemonicOrProfile(reason: String)
	}
}
