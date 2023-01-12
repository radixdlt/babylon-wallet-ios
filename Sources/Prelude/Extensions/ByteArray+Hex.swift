import Foundation

public extension Array where Element == UInt8 {
	init(hex: String) throws {
		try self.init(Data(hex: hex))
	}

	@inlinable
	func hex(options: Data.HexEncodingOptions = []) -> String {
		Data(self).hex(options: options)
	}
}
