// MARK: - HexCodable
/// A thin wrapper around `Data` making sure it is always Encoded to a hexadecimal string and can
/// always be decoded from a hexadecimal string. It is also `Sendable`, `Identifiable`, and conforms
/// to `DataProtocol`.
///
/// This type is made obsolete if one is using custom Encoder/Decoder using `Hex` as Data encoding/
/// decoding strategy, but it is quite strict to require that because some data we might want to
/// Base64 encode/decode. An alternative is of course to create a variant of this type but `Base64Codable`,
/// which overrides the data coding strategy of the encoder.
struct HexCodable:
	Sendable,
	Hashable,
	Codable,
	Identifiable,
	CustomStringConvertible,
	DataProtocol
{
	/// The underlying `Data` that is always hex coded.
	let data: Data

	init(data: Data) {
		self.data = data
	}
}

// MARK: Hex
extension HexCodable {
	init(hex: String) throws {
		try self.init(data: Data(hex: hex))
	}

	func hex(options: Data.HexEncodingOptions = []) -> String {
		data.hex(options: options)
	}
}

extension String {
	func mask(showLast suffixCount: Int) -> String.SubSequence {
		"..." + suffix(suffixCount)
	}
}

// MARK: Identifiable
extension HexCodable {
	typealias ID = String

	/// The underlying `data` as a hex string.
	var id: ID {
		data.hex()
	}
}

// MARK: DataProtocol
extension HexCodable {
	typealias Regions = Data.Regions

	var regions: Regions {
		data.regions
	}
}

// MARK: RandomAccessCollection
extension HexCodable {
	typealias Element = Data.Element
	typealias SubSequence = Data.SubSequence
	typealias Index = Data.Index
	typealias Indices = Data.Indices

	var endIndex: Index {
		data.endIndex
	}

	var indices: Indices {
		data.indices
	}

	var startIndex: Index {
		data.startIndex
	}

	func formIndex(after index: inout Index) {
		data.formIndex(after: &index)
	}

	func formIndex(before index: inout Index) {
		data.formIndex(before: &index)
	}

	subscript(bounds: Range<Index>) -> SubSequence {
		data[bounds]
	}

	subscript(position: Index) -> Element {
		data[position]
	}
}

// MARK: Codable
extension HexCodable {
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let data = try Data(hex: container.decode(String.self))
		self.init(data: data)
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(data.hex())
	}
}

// MARK: CustomStringConvertible
extension HexCodable {
	var description: String {
		data.hex()
	}
}

#if canImport(CustomDump)
extension HexCodable: CustomDumpRepresentable {
	var customDumpValue: Any {
		data.hex()
	}
}
#endif // canImport(CustomDump)

#if DEBUG
extension HexCodable: ExpressibleByStringLiteral {
	init(stringLiteral value: StringLiteralType) {
		try! self.init(hex: value)
	}
}

extension HexCodable {
	static let deadbeef32Bytes = Self(data: .deadbeef32Bytes)
}
#endif // DEBUG

// MARK: - CodableViaHexCodable
typealias CodableViaHexCodable = DecodableViaHexCodable & EncodableViaHexCodable

// MARK: - EncodableViaHexCodable
protocol EncodableViaHexCodable: Encodable {
	var hexCodable: HexCodable { get }
}

// MARK: - DecodableViaHexCodable
protocol DecodableViaHexCodable: Decodable {
	init(hexCodable: HexCodable) throws
}

extension EncodableViaHexCodable {
	func hex(options: Data.HexEncodingOptions = []) -> String {
		self.hexCodable.hex(options: options)
	}
}

extension DecodableViaHexCodable {
	init(hex: String) throws {
		try self.init(data: .init(hex: hex))
	}

	init(data: Data) throws {
		try self.init(hexCodable: .init(data: data))
	}
}

extension EncodableViaHexCodable {
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.hexCodable)
	}
}

extension DecodableViaHexCodable {
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		try self.init(hexCodable: container.decode(HexCodable.self))
	}
}
