import Foundation

public typealias PackageAddress = SpecificAddress<PackageAddressKind>
public typealias ResourceAddress = SpecificAddress<ResourceAddressKind>
public typealias ComponentAddress = SpecificAddress<ComponentAddressKind>

// MARK: - SpecificAddressKind
public protocol SpecificAddressKind: Sendable {
	static func validate(address: String) throws
	static var type: AddressDiscriminator { get }
}

// MARK: - AddressDiscriminator
public enum AddressDiscriminator: String, Sendable, Hashable, Codable {
	case packageAddress = "PackageAddress"
	case resourceAddress = "ResourceAddress"
	case componentAddress = "ComponentAddress"
}

// MARK: - PackageAddressKind
public enum PackageAddressKind: SpecificAddressKind {
	public static func validate(address: String) throws {}
	public static let type: AddressDiscriminator = .packageAddress
}

// MARK: - ResourceAddressKind
public enum ResourceAddressKind: SpecificAddressKind {
	public static func validate(address: String) throws {}
	public static let type: AddressDiscriminator = .resourceAddress
}

// MARK: - ComponentAddressKind
public enum ComponentAddressKind: SpecificAddressKind {
	public static func validate(address: String) throws {}
	public static let type: AddressDiscriminator = .componentAddress
}

extension SpecificAddress {
	public init(validatingAddress address: String) throws {
		try Kind.validate(address: address)
		self.init(address: address)
	}
}

// MARK: - SpecificAddress
public struct SpecificAddress<Kind: SpecificAddressKind>: AddressProtocol, Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let type: AddressDiscriminator = Kind.type
	public let address: String

	// MARK: Init

	public init(address: String) {
		// TODO: Perform some simple Bech32m validation.
		self.address = address
	}

	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case address, type
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Kind.type, forKey: .type)
		try container.encode(address, forKey: .address)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(AddressDiscriminator.self, forKey: .type)
		if type != Kind.type {
			throw InternalDecodingFailure.addressDiscriminatorMismatch(expected: Kind.type, butGot: type)
		}

		try self.init(
			address: container.decode(String.self, forKey: .address)
		)
	}
}

extension SpecificAddress {
	public var asGeneral: Address_ {
		.init(address: address)
	}
}

extension Address_ {
	public func asSpecific<Kind: SpecificAddressKind>() throws -> SpecificAddress<Kind> {
		do {
			return try .init(validatingAddress: address)
		} catch {
			throw ConversionError.failedCreating(kind: Kind.self)
		}
	}

	public func isKind(_ kind: SpecificAddressKind.Type) -> Bool {
		(try? kind.validate(address: address)) != nil
	}

	public enum ConversionError: Error {
		case failedCreating(kind: SpecificAddressKind.Type)
		case addressKindMismatch(desired: SpecificAddressKind.Type, actual: SpecificAddressKind.Type)
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

extension AddressProtocol {
	public init(stringLiteral value: String) {
		self.init(address: value)
	}
}

// MARK: - PolymorphicAddress
public enum PolymorphicAddress: Sendable, Codable, Hashable, AddressStringConvertible {
	case packageAddress(PackageAddress)
	case componentAddress(ComponentAddress)
	case resourceAddress(ResourceAddress)
}

// MARK: Codable
extension PolymorphicAddress {
	private enum CodingKeys: String, CodingKey {
		case type
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(AddressDiscriminator.self, forKey: .type)

		let singleValueContainer = try decoder.singleValueContainer()
		switch discriminator {
		case .packageAddress:
			self = try .packageAddress(singleValueContainer.decode(PackageAddress.self))
		case .componentAddress:
			self = try .componentAddress(singleValueContainer.decode(ComponentAddress.self))
		case .resourceAddress:
			self = try .resourceAddress(singleValueContainer.decode(ResourceAddress.self))
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

extension PolymorphicAddress {
	public var address: String {
		switch self {
		case let .packageAddress(address): return address.address
		case let .componentAddress(address): return address.address
		case let .resourceAddress(address): return address.address
		}
	}
}
