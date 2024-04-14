import Foundation
import Sargon

extension BIP44LikePath {
	public init(index: HDPathValue) throws {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public var asGeneral: DerivationPath {
		.bip44Like(value: self)
	}
}
