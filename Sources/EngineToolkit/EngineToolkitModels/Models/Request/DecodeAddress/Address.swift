import Foundation

// MARK: - AddressKindPrefix
// TODO: Find a solution to to use EngineToolkit.decodeAddress to determine the kind of an Address.
// Currently it is not possible to do due to potential circular dependency between EngineToolkit and EngineToolkitModels

/// RET removed the information about what kind of Address we do receive.
/// We try to determine the kind of Address by a given prefix.
///
public enum AddressKindPrefix: String, CaseIterable {
	case account
	case resource
	case package
	case component
	case clock
	case epochManager = "epochmanager"
	case accesscontroller
	case validator
	case identity

	/// Group together all component addresses, so we can treat any of the sub-address as a component address
	static let componentAddressSet: Set<AddressKindPrefix> = [.account, .component, .clock, .epochManager, .accesscontroller, .validator, .identity]
	/// Group together all of the addresses under entity address set, so any address can be an EntityAddress
	static let entityAddressSet: Set<AddressKindPrefix> = Set(AddressKindPrefix.allCases)
}

/// Any Entity Address
public typealias EntityAddress = SpecificAddress<EntityAddressKind>

/// Describes a package address, i.e `package_tdx_....`
public typealias PackageAddress = SpecificAddress<PackageAddressKind>
/// Describes a resource address, i.e `resource_tdx_....`
public typealias ResourceAddress = SpecificAddress<ResourceAddressKind>

/// A component specific address, can be any of `AddressKindPrefix.componentAddressSet`
public typealias ComponentAddress = SpecificAddress<ComponentAddressKind>
/// Account specific address
public typealias AccountAddress_ = SpecificAddress<AccountAddressKind>
/// Identity specific address
public typealias IdentityAddress_ = SpecificAddress<IdentityAddressKind>
/// Access Controller specific address
public typealias AccessControllerAddress = SpecificAddress<AccessControllerAddressKind>

// MARK: - EntityAddressKind
public enum EntityAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKindPrefix> = AddressKindPrefix.entityAddressSet
}

// MARK: - ResourceAddressKind
public enum ResourceAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKindPrefix> = [.resource]
}

// MARK: - PackageAddressKind
public enum PackageAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKindPrefix> = [.package]
}

// MARK: - ComponentAddressKind
public enum ComponentAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKindPrefix> = AddressKindPrefix.componentAddressSet
}

// MARK: - AccountAddressKind
public enum AccountAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKindPrefix> = [.account]
}

// MARK: - IdentityAddressKind
public enum IdentityAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKindPrefix> = [.identity]
}

// MARK: - AccessControllerAddressKind
public enum AccessControllerAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKindPrefix> = [.accesscontroller]
}

// MARK: - SpecificAddressKind
public protocol SpecificAddressKind: Sendable {
	/// The valid address space that can match a given kind of addresses
	static var addressSpace: Set<AddressKindPrefix> { get }
}

// MARK: - SpecificAddress
public struct SpecificAddress<Kind: SpecificAddressKind>: Sendable, Hashable, Codable, AddressProtocol {
	public let address: String

	enum CodingKeys: CodingKey {
		case address
	}

	public init(address: String) {
		self.address = address
	}

	// MARK: Init

	public init(validatingAddress address: String) throws {
		guard Kind.addressSpace.contains(where: { address.contains($0.rawValue) }) else {
			throw NSError(domain: "", code: 1)
		}
		self.init(address: address)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let address = try container.decode(String.self)
		try self.init(validatingAddress: address)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.address, forKey: .address)
	}
}

extension SpecificAddress {
	/// Convert the address to a given kind, by validating the conversion
	public func converted<Kind: SpecificAddressKind>() throws -> SpecificAddress<Kind> {
		try .init(validatingAddress: self.address)
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

extension SpecificAddress {
	public var asGeneral: Address_ {
		.init(address: address)
	}
}

extension Address_ {
	public func asSpecific<Kind: SpecificAddressKind>() throws -> SpecificAddress<Kind> {
		try .init(validatingAddress: address)
	}
}
