import Foundation

// https://gist.github.com/hannesoid/10a35895e4dc5d6f1bb6428f7d4d23a5
public indirect enum JSONValue: Codable, CustomStringConvertible, Sendable, Hashable {
	case double(Double)
        case int32(Int32)
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
		} else if let value = try? singleValueContainer.decode(Int32.self) {
                        self = .int32(value)
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

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		switch self {
		case let .array(array): try container.encode(array)
		case let .dictionary(object): try container.encode(object)
		case let .double(double):
			try container.encode(double)
		case let .string(string): try container.encode(string)
		case let .bool(bool): try container.encode(bool)
		case .nil: try container.encodeNil()
                case let .int32(int): try container.encode(int)
                }
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
                case let .int32(int):
                        return "\(int)"
                }
	}
}

// MARK: - Convenience
public extension JSONValue {
        var string: String? {
                switch self {
                case let .string(value):
                        return value
                default:
                        return nil
                }
        }

        var double: Double? {
                switch self {
                case let .double(value):
                        return value
                default:
                        return nil
                }
        }

        var bool: Bool? {
                switch self {
                case let .bool(value):
                        return value
                default:
                        return nil
                }
        }

        var dictionary: [String: JSONValue]? {
                switch self {
                case let .dictionary(value):
                        return value
                default:
                        return nil
                }
        }

        var array: [JSONValue]? {
                switch self {
                case let .array(value):
                        return value
                default:
                        return nil
                }
        }

        var isNil: Bool {
                switch self {
                case .nil:
                        return true
                default:
                        return false
                }
        }
}
