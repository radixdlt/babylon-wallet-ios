import Foundation
import Sargon
import Tagged

extension NetworkDefinition {
	typealias Name = Tagged<Self, String>
	static func lookupBy(name: Name) throws -> Self {
		try lookupBy(logicalName: name.rawValue)
	}
}
