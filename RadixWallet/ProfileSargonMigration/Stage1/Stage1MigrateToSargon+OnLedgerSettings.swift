import Foundation
import Sargon

extension OnLedgerSettings {
	public static var `default`: Self {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}
