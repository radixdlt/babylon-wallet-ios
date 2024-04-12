import Foundation
import Sargon

extension AppPreferences {
	public static var `default`: Self {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}
