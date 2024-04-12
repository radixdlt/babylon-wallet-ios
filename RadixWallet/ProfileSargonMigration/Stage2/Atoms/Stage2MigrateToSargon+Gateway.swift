import Foundation
import Sargon

extension Gateway {
	public var isWellknown: Bool {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}
