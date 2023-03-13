import Foundation

// MARK: - Address
public enum Address: Sendable, Codable, Hashable, AddressStringConvertible {
	case packageAddress(PackageAddress)
	case componentAddress(ComponentAddress)
	case resourceAddress(ResourceAddress)
}

// MARK: Codable
extension Address {
	private enum CodingKeys: String, CodingKey {
		case type
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let singleValueContainer = try decoder.singleValueContainer()
		let discriminator = try container.decode(ManifestASTValueKind.self, forKey: .type)
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

	public func encode(to encoder: Encoder) throws {
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

extension Address {
	public var componentAddress: ComponentAddress? {
		switch self {
		case let .componentAddress(componentAddress): return componentAddress
		case .packageAddress, .resourceAddress: return nil
		}
	}

	public var asAccountComponentAddress: ComponentAddress? {
		guard let componentAddress else {
			return nil
		}
		return componentAddress.asAccountComponentAddress
	}
}

extension ComponentAddress {
	public var asAccountComponentAddress: ComponentAddress? {
		guard isAccountAddress else { return nil }
		return self
	}

	public var isAccountAddress: Bool {
		address.starts(with: "account")
	}
}

// MARK: - AddressProtocol
public protocol AddressProtocol: AddressStringConvertible, ExpressibleByStringLiteral {
	init(address: String)
}

extension AddressProtocol {
	public init(stringLiteral value: String) {
		self.init(address: value)
	}
}

extension Address {
	public var address: String {
		switch self {
		case let .packageAddress(address): return address.address
		case let .componentAddress(address): return address.address
		case let .resourceAddress(address): return address.address
		}
	}
}
