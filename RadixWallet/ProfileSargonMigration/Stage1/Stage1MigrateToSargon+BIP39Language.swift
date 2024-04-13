import Foundation
import Sargon

public typealias BIP39Language = Bip39Language

extension BIP39Language {
	public func wordlist() -> [BIP39Word] {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}
