import Foundation
import Sargon

extension MnemonicWithPassphrase {
	public func toSeed() -> BIP39Seed {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}
