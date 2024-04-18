import Foundation
import Sargon

extension MnemonicWithPassphrase {
	public func toSeed() -> BIP39Seed {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - MnemonicWithPassphrase + Codable
extension MnemonicWithPassphrase: Codable {
	public init(from decoder: any Decoder) throws {
		fatalError()
	}

	public func encode(to encoder: any Encoder) throws {
		fatalError()
	}
}
