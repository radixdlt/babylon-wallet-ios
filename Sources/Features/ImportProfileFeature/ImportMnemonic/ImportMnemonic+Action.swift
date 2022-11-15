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

// MARK: - ImportMnemonic.Action.ViewAction
public extension ImportMnemonic.Action {
	enum ViewAction: Equatable {
		case goBackButtonTapped
		case importMnemonicButtonTapped
		case importProfileFromSnapshotButtonTapped
		case saveImportedMnemonicButtonTapped
		case phraseOfMnemonicToImportChanged(String)
	}
}

// MARK: - ImportMnemonic.Action.InternalAction
public extension ImportMnemonic.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ImportMnemonic.Action.SystemAction
public extension ImportMnemonic.Action {
	enum SystemAction: Equatable {
		case importMnemonicResult(TaskResult<Mnemonic>)
		case saveImportedMnemonicResult(TaskResult<Mnemonic>)
		case profileFromSnapshotResult(TaskResult<Profile>)
	}
}

// MARK: - ImportMnemonic.Action.DelegateAction
public extension ImportMnemonic.Action {
	enum DelegateAction: Equatable {
		case goBack
		case finishedImporting(mnemonic: Mnemonic, andProfile: Profile)
	}
}
