import Cryptography
import Prelude
import Profile

// MARK: ImportMnemonic.State
public extension ImportMnemonic {
	struct State: Equatable {
		public var importedProfileSnapshot: ProfileSnapshot
		public var phraseOfMnemonicToImport: String
		public var importedMnemonic: Mnemonic?
		public var savedMnemonic: Mnemonic?

		public init(
			importedProfileSnapshot: ProfileSnapshot,
			phraseOfMnemonicToImport: String = "bright club bacon dinner achieve pull grid save ramp cereal blush woman humble limb repeat video sudden possible story mask neutral prize goose mandate"
		) {
			self.importedProfileSnapshot = importedProfileSnapshot
			self.phraseOfMnemonicToImport = phraseOfMnemonicToImport
		}
	}
}
