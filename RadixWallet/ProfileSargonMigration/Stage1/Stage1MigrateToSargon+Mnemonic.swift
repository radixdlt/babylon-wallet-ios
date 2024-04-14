import Foundation
import Sargon

extension Mnemonic {
	public init(words: some Collection<BIP39Word>) throws {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public init(phrase: String, language: BIP39Language) throws {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public static var sample24ZooVote: Self {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}
