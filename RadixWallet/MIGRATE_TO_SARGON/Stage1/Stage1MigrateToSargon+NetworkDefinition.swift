import Foundation
import Sargon
import SargonUniFFI
import Tagged

extension NetworkDefinition {
	typealias Name = Tagged<Self, String>
	static func lookupBy(name: Name) throws -> Self {
		try lookupBy(logicalName: name.rawValue)
	}

	static func lookupBy(id: NetworkID) throws -> Self {
		try lookupBy(networkId: id)
	}
}
