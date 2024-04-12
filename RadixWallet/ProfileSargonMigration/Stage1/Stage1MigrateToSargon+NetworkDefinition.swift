import Foundation
import Sargon
import Tagged

extension NetworkDefinition {
	public typealias Name = Tagged<Self, String>
	public static func lookupBy(name: Name) throws -> Self {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}
