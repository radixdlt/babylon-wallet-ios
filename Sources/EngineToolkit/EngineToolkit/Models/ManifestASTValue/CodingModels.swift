import CasePaths

// MARK: - ValueCodable
public struct ValueCodable<Value: Codable>: Codable {
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
struct IntegerCodable<I: FixedWidthInteger & Codable>: Codable {
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

// MARK: - IntFromStringCodable
struct IntFromStringCodable<I: FixedWidthInteger & Codable>: Codable {
	let value: I

	init(_ value: I) {
		self.value = value
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()

		if let value = try I(container.decode(String.self)) {
			self.value = value
		} else {
			throw InternalDecodingFailure.parsingError
		}
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(String(value))
	}
}

// struct IntegerArrayCodable<I: FixedWidthInteger & Codable>: Codable {
//        let value: [I]
//
//        init(_ value: [I]) {
//                self.value = value
//        }
//
//        init(from decoder: Decoder) throws {
//                let str: String = try ValueCodable(from: decoder).value
//                if let value = I(str) {
//                        self.value = value
//                } else {
//                        throw InternalDecodingFailure.parsingError
//                }
//        }
//
//        func encode(to encoder: Encoder) throws {
//                try ValueCodable(String(value)).encode(to: encoder)
//        }
// }
