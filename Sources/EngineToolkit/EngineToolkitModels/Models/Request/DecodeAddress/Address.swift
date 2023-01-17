import Foundation

// MARK: - Address
public enum Address: Sendable, Codable, Hashable, AddressStringConvertible {
	case packageAddress(PackageAddress)
	case componentAddress(ComponentAddress)
	case resourceAddress(ResourceAddress)
}

// MARK: Codable
public extension Address {
	private enum CodingKeys: String, CodingKey {
		case type
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let singleValueContainer = try decoder.singleValueContainer()
		let discriminator = try container.decode(ValueKind.self, forKey: .type)
		switch discriminator {
		case .packageAddress:
			self = try .packageAddress(singleValueContainer.decode(PackageAddress.self))
		case .componentAddress:
			self = try .componentAddress(singleValueContainer.decode(ComponentAddress.self))
		case .resourceAddress:
			self = try .resourceAddress(singleValueContainer.decode(ResourceAddress.self))
		default:
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expectedAnyOf: [.componentAddress, .packageAddress, .resourceAddress], butGot: discriminator)
		}
	}

	func encode(to encoder: Encoder) throws {
		var singleValueContainer = encoder.singleValueContainer()
		switch self {
		case let .packageAddress(encodable):
			try singleValueContainer.encode(encodable)
		case let .componentAddress(encodable):
			try singleValueContainer.encode(encodable)
		case let .resourceAddress(encodable):
			try singleValueContainer.encode(encodable)
		}
	}
}

// MARK: - AddressStringConvertible
public protocol AddressStringConvertible {
	var address: String { get }
}

// MARK: - AddressProtocol
public protocol AddressProtocol: AddressStringConvertible, ExpressibleByStringLiteral {
	init(address: String)
}

public extension AddressProtocol {
	init(stringLiteral value: String) {
		self.init(address: value)
	}
}

public extension Address {
	var address: String {
		switch self {
		case let .packageAddress(address): return address.address
		case let .componentAddress(address): return address.address
		case let .resourceAddress(address): return address.address
		}
	}
}
