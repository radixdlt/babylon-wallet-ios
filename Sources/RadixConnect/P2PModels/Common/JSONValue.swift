import Foundation

// MARK: - JSONValue
// https://gist.github.com/hannesoid/10a35895e4dc5d6f1bb6428f7d4d23a5
public indirect enum JSONValue: Decodable, CustomStringConvertible, Sendable, Hashable {
	case double(Double)
	case string(String)
	case bool(Bool)
	case dictionary([String: JSONValue])
	case array([JSONValue])
	case `nil`

	public init(from decoder: Decoder) throws {
		let singleValueContainer = try decoder.singleValueContainer()
		if let value = try? singleValueContainer.decode(Bool.self) {
			self = .bool(value)
			return
		} else if let value = try? singleValueContainer.decode(String.self) {
			self = .string(value)
			return
		} else if let value = try? singleValueContainer.decode(Double.self) {
			self = .double(value)
			return
		} else if let value = try? singleValueContainer.decode([String: JSONValue].self) {
			self = .dictionary(value)
			return
		} else if let value = try? singleValueContainer.decode([JSONValue].self) {
			self = .array(value)
			return
		} else if singleValueContainer.decodeNil() {
			self = .nil
			return
		}

		throw DecodingError.dataCorrupted(
			DecodingError.Context(
				codingPath: decoder.codingPath,
				debugDescription: "Could not find reasonable type to map to JSONValue"
			)
		)
	}

	public var description: String {
		stringRepresentation
	}

	private var stringRepresentation: String {
		switch self {
		case .nil:
			return "null"
		case let .array(array):
			return "[" + array.map { $0.stringRepresentation /* recursion */ }.joined(separator: ", ") + "]"
		case let .bool(bool):
			return bool ? "true" : "false"
		case let .double(double):
			let formatter = NumberFormatter()
			formatter.maximumFractionDigits = 3
			return formatter.string(for: double)!
		case let .string(string):
			return string
		case let .dictionary(dictionary):
			return dictionary.map {
				"\($0.key): \($0.value.stringRepresentation)"
			}.joined(separator: ", ")
		}
	}
}

// MARK: - Convenience
extension JSONValue {
	public var string: String? {
		switch self {
		case let .string(value):
			return value
		default:
			return nil
		}
	}

	public var double: Double? {
		switch self {
		case let .double(value):
			return value
		default:
			return nil
		}
	}

	public var bool: Bool? {
		switch self {
		case let .bool(value):
			return value
		default:
			return nil
		}
	}

	public var dictionary: [String: JSONValue]? {
		switch self {
		case let .dictionary(value):
			return value
		default:
			return nil
		}
	}

	public var array: [JSONValue]? {
		switch self {
		case let .array(value):
			return value
		default:
			return nil
		}
	}

	public var isNil: Bool {
		switch self {
		case .nil:
			return true
		default:
			return false
		}
	}
}
