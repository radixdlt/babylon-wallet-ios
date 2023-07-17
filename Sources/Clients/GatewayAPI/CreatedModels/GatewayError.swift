import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.GatewayError")
public typealias GatewayError = GatewayAPI.GatewayError

// MARK: - GatewayAPI.GatewayError
extension GatewayAPI {
	public enum GatewayError: Codable, JSONEncodable, Hashable {
		case anyCodable(AnyCodable)
		case entityNotFoundError(EntityNotFoundError)
		case internalServerError(InternalServerError)
		case invalidEntityError(InvalidEntityError)
		case invalidRequestError(InvalidRequestError)
		case notSyncedUpError(NotSyncedUpError)
		case transactionNotFoundError(TransactionNotFoundError)

		public func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			switch self {
			case let .anyCodable(value):
				try container.encode(value)
			case let .entityNotFoundError(value):
				try container.encode(value)
			case let .internalServerError(value):
				try container.encode(value)
			case let .invalidEntityError(value):
				try container.encode(value)
			case let .invalidRequestError(value):
				try container.encode(value)
			case let .notSyncedUpError(value):
				try container.encode(value)
			case let .transactionNotFoundError(value):
				try container.encode(value)
			}
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			if let value = try? container.decode(AnyCodable.self) {
				self = .anyCodable(value)
			} else if let value = try? container.decode(EntityNotFoundError.self) {
				self = .entityNotFoundError(value)
			} else if let value = try? container.decode(InternalServerError.self) {
				self = .internalServerError(value)
			} else if let value = try? container.decode(InvalidEntityError.self) {
				self = .invalidEntityError(value)
			} else if let value = try? container.decode(InvalidRequestError.self) {
				self = .invalidRequestError(value)
			} else if let value = try? container.decode(NotSyncedUpError.self) {
				self = .notSyncedUpError(value)
			} else if let value = try? container.decode(TransactionNotFoundError.self) {
				self = .transactionNotFoundError(value)
			} else {
				throw DecodingError.typeMismatch(Self.Type.self, .init(codingPath: decoder.codingPath, debugDescription: "Unable to decode instance of GatewayError"))
			}
		}
	}
}
