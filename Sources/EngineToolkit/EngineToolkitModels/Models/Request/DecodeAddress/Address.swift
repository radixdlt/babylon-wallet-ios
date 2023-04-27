import Foundation

// MARK: - AddressKindPrefix
public enum AddressKindPrefix: String {
        case account
	case resource
	case package
	case component
	case clock
	case epochManager = "epochmanager"
        case accesscontroller
        case validator
        case identity
}



public protocol SpecificAddressKind: Sendable {
        static func validate(address: String) throws
        static var type: AddressKind { get }
}

typealias GlobalComponentAdress = SpecificAddress<GlobalComponentAdressKind>

typealias FungibleResourceAddress = SpecificAddress<FungibleAdressKind>
typealias NonFungibleResourceAdress = SpecificAddress<NonFungibleAdressKind>
typealias ResourceAddress = SpecificAddress<ResourceAddressKind>

public enum GlobalComponentAdressKind: SpecificAddressKind {
        public static func validate(address: String) throws {}
        public static let type: AddressKind = .globalGenericComponent
}

public enum ComponentAddressKind {
        public static func validate(address: String) throws {}
        public static let type: Set<AddressKind> = [.globalGenericComponent, .internalGenericComponent, .globalAccount, .internalAccount, .]
}

public enum FungibleAdressKind: SpecificAddressKind {
        public static func validate(address: String) throws {}
        public static let type: AddressKind = .globalFungibleResource
}

public enum NonFungibleAdressKind: SpecificAddressKind {
        public static func validate(address: String) throws {}
        public static let type: AddressKind = .globalNonFungibleResource
}

public enum ResourceAddressKind: SpecificAddressKind {
        public static func validate(address: String) throws {}
        public static let type: Set<AddressKind> = [.globalNonFungibleResource, .globalNonFungibleResource]
}

public struct SpecificAddress<Kind: SpecificAddressKind>: AddressProtocol, Sendable , Hashable {
        // MARK: Stored properties
        public let type: AddressKind = Kind.type
        public let address: String
        
        // MARK: Init
        
        public init(address: String) {
                self.address = address
        }

        func asSpecific
}


// MARK: - ResourceAddress
public struct ResourceAddress: Codable, Hashable, Sendable, EntityAddress {
	public static let prefixes: Set<AddressKindPrefix> = [.resource]
	public var address: String

	public init(address: String) {
		self.address = address
	}
}

// MARK: - PackageAddress
public struct PackageAddress: Codable, Hashable, Sendable, EntityAddress {
	public static let prefixes: Set<AddressKindPrefix> = [.package]
	public var address: String

	public init(address: String) {
		self.address = address
	}
}

// MARK: - ComponentAddress
public struct ComponentAddress: Codable, Hashable, Sendable, EntityAddress {
        public static let prefixes: Set<AddressKindPrefix> = [.component, .account, .clock, .epochManager, .accesscontroller, .validator, .identity]
	public var address: String

	public init(address: String) {
		self.address = address
	}
}

// MARK: - ClockAddress
public struct ClockAddress: Codable, Hashable, Sendable, EntityAddress {
	public static let prefixes: Set<AddressKindPrefix> = [.clock]
	public var address: String

	public init(address: String) {
		self.address = address
	}
}

// MARK: - EpochManagerAddress
public struct EpochManagerAddress: Codable, Hashable, Sendable, EntityAddress {
	public static let prefixes: Set<AddressKindPrefix> = [.epochManager]
	public var address: String

	public init(address: String) {
		self.address = address
	}
}

// MARK: - EntityAddress
public protocol EntityAddress: AddressProtocol, Codable {
	static var prefixes: Set<AddressKindPrefix> { get }
	var address: String { get set }

	init(address: String)
}

// MARK: - InvalidAddressTypeError
public struct InvalidAddressTypeError: Error {
	public let message: String
}

extension EntityAddress {
	public init(validatingAddress address: String) throws {
                guard Self.prefixes.contains(where: { address.hasPrefix($0.rawValue)} ) else {
			throw InvalidAddressTypeError(message: "Failed to decode \(address), expected on of prefixes: \(Self.prefixes)")
		}
		self.init(address: address)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		try self.init(validatingAddress: container.decode(String.self))
	}
}

extension EntityAddress {
	public var asGeneral: Address_ {
		.init(address: address)
	}
}

extension Address_ {
	public func asSpecific<Address: EntityAddress>() throws -> Address {
		try .init(validatingAddress: address)
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
public enum PolymorphicAddress: Sendable, Decodable, Hashable, AddressStringConvertible {
	case packageAddress(PackageAddress)
	case componentAddress(ComponentAddress)
	case resourceAddress(ResourceAddress)
}

// MARK: Codable
extension PolymorphicAddress {
	struct UnknownAddressKindPrefix: Error {}

        private enum CodingKeys: String, CodingKey {
                case address
        }

	public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)

                let address = try container.decode(String.self, forKey: .address)

		// Prefix until first `_`. E.g package_tdx_....
		let rawPrefix = String(address.prefix(while: { $0 != "_" }))
		guard let prefix = AddressKindPrefix(rawValue: rawPrefix) else {
			throw UnknownAddressKindPrefix()
		}

		switch prefix {
		case .resource:
			self = .resourceAddress(ResourceAddress(address: address))
		case .package:
			self = .packageAddress(PackageAddress(address: address))
                case .component, .account, .clock, .epochManager, .accesscontroller, .validator, .identity:
			self = .componentAddress(ComponentAddress(address: address))
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
