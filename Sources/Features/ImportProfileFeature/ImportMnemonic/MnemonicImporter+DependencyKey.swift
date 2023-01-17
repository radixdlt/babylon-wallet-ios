import Cryptography
import FeaturePrelude

public typealias MnemonicImporter = @Sendable (String) throws -> Mnemonic

// MARK: - MnemonicImporterKey
private enum MnemonicImporterKey: DependencyKey {
	typealias Value = MnemonicImporter
	static let liveValue = { @Sendable in try Mnemonic(phrase: $0, language: nil) }
}

public extension DependencyValues {
	var mnemonicImporter: MnemonicImporter {
		get { self[MnemonicImporterKey.self] }
		set { self[MnemonicImporterKey.self] = newValue }
	}
}
