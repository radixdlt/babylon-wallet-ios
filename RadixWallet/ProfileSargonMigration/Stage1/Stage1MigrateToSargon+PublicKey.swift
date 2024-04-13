import Foundation
import Sargon

extension Sargon.PublicKey {
	public var curve: SLIP10Curve {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}
