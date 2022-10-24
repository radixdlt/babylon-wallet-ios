import ComposableArchitecture
import Foundation
import Mnemonic

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
