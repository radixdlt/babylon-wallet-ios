import Foundation

// MARK: - AddressKindPrefix
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

	static let componentAddressSet: Set<AddressKindPrefix> = [.account, .component, .clock, .epochManager, .accesscontroller, .validator, .identity]
}

public typealias PackageAddress = SpecificAddress<PackageAddressKind>
public typealias ComponentAddress = SpecificAddress<ComponentAddressKind>
public typealias ResourceAddress = SpecificAddress<ResourceAddressKind>
public typealias AccountAddress_ = SpecificAddress<AccountAddressKind>
public typealias EntityAddress = SpecificAddress<EntityAddressKind>
public typealias IdentityAddress_ = SpecificAddress<IdentityAddressKind>
public typealias AccessControllerAddress = SpecificAddress<AccessControllerAddressKind>

// MARK: - EntityAddressKind
public enum EntityAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKindPrefix> = Set(AddressKindPrefix.allCases)
}

// MARK: - ComponentAddressKind
public enum ComponentAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKindPrefix> = AddressKindPrefix.componentAddressSet
}

// MARK: - ResourceAddressKind
public enum ResourceAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKindPrefix> = [.resource]
}

// MARK: - PackageAddressKind
public enum PackageAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKindPrefix> = [.package]
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
	static var addressSpace: Set<AddressKindPrefix> { get }
}

extension SpecificAddress {
	public func converted<Kind: SpecificAddressKind>() throws -> SpecificAddress<Kind> {
		try .init(validatingAddress: self.address)
	}
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
