public struct HexCodable32Bytes: Sendable, Codable, Equatable, Hashable {
	struct IncorretByteCountError: Swift.Error {
		let got: Int
		let expected: Int
	}

	static let byteCount = 32

	public let data: HexCodable
	public init(_ data: HexCodable) throws {
		guard data.count == Self.byteCount else {
			throw IncorretByteCountError(got: data.count, expected: Self.byteCount)
		}
		self.data = data
	}

	public init(data: Data) throws {
		try self.init(.init(data: data))
	}

	public init(hex: String) throws {
		try self.init(data: Data(hex: hex))
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(data)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		try self.init(container.decode(HexCodable.self))
	}
}
