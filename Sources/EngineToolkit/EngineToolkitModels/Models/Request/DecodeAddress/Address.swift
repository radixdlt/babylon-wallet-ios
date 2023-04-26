import Foundation

public enum AddressKindPrefix: String {
        case resource = "resource"
        case package = "package"
        case component = "component"
        case clock = "clock"
        case epochManager = "epochmanager"
}

public struct ResourceAddress: Codable, Hashable, Sendable, EntityAddress {
        public static let prefix: AddressKindPrefix = .resource
        public var address: String

        public init(address: String) {
                self.address = address
        }
}

public struct PackageAddress: Codable, Hashable, Sendable, EntityAddress {
        public static let prefix: AddressKindPrefix = .package
        public var address: String

        public init(address: String) {
                self.address = address
        }
}

public struct ComponentAddress: Codable, Hashable, Sendable, EntityAddress {
        public static let prefix: AddressKindPrefix = .component
        public var address: String

        public init(address: String) {
                self.address = address
        }
}

public struct ClockAddress: Codable, Hashable, Sendable, EntityAddress {
        public static let prefix: AddressKindPrefix = .clock
        public var address: String

        public init(address: String) {
                self.address = address
        }
}

public struct EpochManagerAddress: Codable, Hashable, Sendable, EntityAddress {
        public static let prefix: AddressKindPrefix = .epochManager
        public var address: String

        public init(address: String) {
                self.address = address
        }
}

public protocol EntityAddress: AddressProtocol, Codable {
        static var prefix: AddressKindPrefix { get }
        var address: String { get set}

        init(address: String)
}

public struct InvalidAddressTypeError: Error {
        public let message: String
}

extension EntityAddress {
        public init(validatingAddress address: String) throws {
                guard address.hasPrefix(Self.prefix.rawValue) else {
                        throw InvalidAddressTypeError(message: "Failed to decode \(address), expected prefix: \(Self.prefix)")
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
        case clockAddress(ClockAddress)
        case epochManagerAddress(EpochManagerAddress)
}

// MARK: Codable
extension PolymorphicAddress {
        struct UnknownAddressKindPrefix: Error {}

	public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()

                let address = try container.decode(String.self)
                // Prefix until first `_`. E.g package_tdx_....
                let rawPrefix = String(address.prefix(while: { $0 != "_"}))
                guard let prefix = AddressKindPrefix(rawValue: rawPrefix) else {
                        throw UnknownAddressKindPrefix()
                }

                switch prefix {
                case .resource:
                        self = .resourceAddress(ResourceAddress(address: address))
                case .package:
                        self = .packageAddress(PackageAddress(address: address))
                case .component:
                        self = .componentAddress(ComponentAddress(address: address))
                case .clock:
                        self = .clockAddress(ClockAddress(address: address))
                case .epochManager:
                        self = .epochManagerAddress(EpochManagerAddress(address: address))
                }
	}
}

extension PolymorphicAddress {
	public var address: String {
		switch self {
		case let .packageAddress(address): return address.address
		case let .componentAddress(address): return address.address
		case let .resourceAddress(address): return address.address
                case let .clockAddress(address): return address.address
                case let .epochManagerAddress(address): return address.address
                }
	}
}
