import EngineToolkit
import Prelude

extension NonFungibleLocalId {
	public static func from(stringFormat: String) throws -> Self {
		try nonFungibleLocalIdFromStr(string: stringFormat)
	}

	public func toString() throws -> String {
		try nonFungibleLocalIdAsStr(value: self)
	}
}
