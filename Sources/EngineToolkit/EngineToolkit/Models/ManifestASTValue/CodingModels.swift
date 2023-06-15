import CasePaths

// MARK: - ValueCodable
public struct ValueCodable<Value: Codable & ValueProtocol>: Codable, ValueProtocol {
	public static var kind: ManifestASTValueKind { Value.kind }
	public static var casePath: CasePath<ManifestASTValue, ValueCodable<Value>> {
		.init(
			embed: { Value.casePath.embed($0.value) },
			extract: { Value.casePath.extract(from: $0).map(ValueCodable.init) }
		)
	}

	public let value: Value

	enum CodingKeys: CodingKey {
		case value
	}

	public init(_ value: Value) {
		self.value = value
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.value = try container.decode(Value.self, forKey: .value)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(value, forKey: .value)
	}
}

// MARK: - IntegerCodable
struct IntegerCodable<I: FixedWidthInteger & Codable & ValueProtocol>: Codable, ValueProtocol {
	static var casePath: CasePaths.CasePath<ManifestASTValue, IntegerCodable<I>> {
		.init(
			embed: { I.casePath.embed($0.value) },
			extract: { I.casePath.extract(from: $0).map(IntegerCodable.init) }
		)
	}

	static var kind: ManifestASTValueKind { I.kind }

	let value: I

	init(_ value: I) {
		self.value = value
	}

	init(from decoder: Decoder) throws {
		let str: String = try ValueCodable(from: decoder).value
		if let value = I(str) {
			self.value = value
		} else {
			throw InternalDecodingFailure.parsingError
		}
	}

	func encode(to encoder: Encoder) throws {
		try ValueCodable(String(value)).encode(to: encoder)
	}
}
