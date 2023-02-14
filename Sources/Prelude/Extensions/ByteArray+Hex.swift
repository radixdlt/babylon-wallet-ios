import Foundation

extension Array where Element == UInt8 {
	public init(hex: String) throws {
		try self.init(Data(hex: hex))
	}

	@inlinable
	public func hex(options: Data.HexEncodingOptions = []) -> String {
		Data(self).hex(options: options)
	}
}
