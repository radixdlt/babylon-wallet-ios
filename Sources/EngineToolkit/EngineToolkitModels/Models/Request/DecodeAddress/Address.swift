import Foundation

public typealias PackageAddress = SpecificAddress<PackageAddressKind>
public typealias ResourceAddress = SpecificAddress<ResourceAddressKind>
public typealias ComponentAddress = SpecificAddress<ComponentAddressKind>

// MARK: - SpecificAddressKind
public protocol SpecificAddressKind: Sendable {
	static func validate(address: String) throws
}

// MARK: - PackageAddressKind
public enum PackageAddressKind: SpecificAddressKind {
	public static func validate(address: String) throws {}
}

// MARK: - ResourceAddressKind
public enum ResourceAddressKind: SpecificAddressKind {
	public static func validate(address: String) throws {}
}

// MARK: - ComponentAddressKind
public enum ComponentAddressKind: SpecificAddressKind {
	public static func validate(address: String) throws {}
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
	public let address: String

	// MARK: Init

	public init(address: String) {
		// TODO: Perform some simple Bech32m validation.
		self.address = address
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(address)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		self.address = try container.decode(String.self)
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

// MARK: - _TemporaryAddressType
/// This type mimics the old enum based Address
public struct _TemporaryAddressType: Sendable, Codable, Hashable {
	public let type: AddressType
	public let address: String

	public init(type: AddressType, address: String) {
		self.type = type
		self.address = address
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		try self.init(
			type: container.decode(AddressType.self, forKey: .type),
			address: container.decode(String.self, forKey: .address)
		)
	}

	private static let kind: String = "PackageAddress"

	public enum AddressType: String, Sendable, Codable, Hashable {
		case packageAddress = "PackageAddress"
		case resourceAddress = "ResourceAddress"
		case componentAddress = "ComponentAddress"
	}
}
