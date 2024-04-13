import Foundation
import Sargon

extension HierarchicalDeterministicPublicKey {
	public var curve: SLIP10Curve {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}
