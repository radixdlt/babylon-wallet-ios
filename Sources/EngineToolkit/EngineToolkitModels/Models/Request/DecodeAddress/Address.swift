import Foundation

public struct AddressType: OptionSet, Decodable, Sendable, Hashable {
        public var rawValue: Int

        public static let globalPackage = AddressType(rawValue: 1 << 0)
        public static let globalFungibleResource = AddressType(rawValue: 1 << 1)
        public static let globalNonFungibleResource = AddressType(rawValue: 1 << 2)
        public static let globalEpochManager = AddressType(rawValue: 1 << 3)
        public static let globalValidator = AddressType(rawValue: 1 << 4)
        public static let globalClock = AddressType(rawValue: 1 << 5)
        public static let globalAccessController = AddressType(rawValue: 1 << 6)
        public static let globalAccount = AddressType(rawValue: 1 << 7)
        public static let globalIdentity = AddressType(rawValue: 1 << 8)
        public static let globalGenericComponent = AddressType(rawValue: 1 << 9)

        public static let globalVirtualEcdsaAccount = AddressType(rawValue: 1 << 10)
        public static let globalVirtualEddsaAccount = AddressType(rawValue: 1 << 11)
        public static let globalVirtualEcdsaIdentity = AddressType(rawValue: 1 << 12)
        public static let globalVirtualEddsaIdentity = AddressType(rawValue: 1 << 13)

        public static let internalFungibleVault = AddressType(rawValue: 1 << 14)
        public static let internalNonFungibleVault = AddressType(rawValue: 1 << 15)
        public static let internalAccount = AddressType(rawValue: 1 << 16)
        public static let internalKeyValueStore = AddressType(rawValue: 1 << 17)
        public static let internalGenericComponent = AddressType(rawValue: 1 << 18)

        public static let resource: AddressType = [.globalFungibleResource, .globalNonFungibleResource]
        public static let component: AddressType = [.account, .identity, .genericComponent, .globalEpochManager, .globalClock, .globalAccessController, .internalFungibleVault, .internalNonFungibleVault, .internalKeyValueStore]
        public static let package: AddressType = [.globalPackage]

        public static let account: AddressType = [.globalAccount, .internalAccount, .globalVirtualEddsaAccount, .globalVirtualEcdsaAccount]
        public static let identity: AddressType = [.globalIdentity, .globalVirtualEddsaIdentity, .globalVirtualEcdsaIdentity]
        public static let genericComponent: AddressType = [.globalGenericComponent, .internalGenericComponent]

        public static let general: AddressType = [.resource, .component, .package]

        public init(rawValue: Int) {
                self.rawValue = rawValue
        }
}

public typealias PackageAddress = SpecificAddress<PackageAddressKind>
public typealias ComponentAddress = SpecificAddress<ComponentAddressKind>
public typealias ResourceAddress = SpecificAddress<ResourceAddressKind>
public typealias AccountAddress = SpecificAddress<AccountAddressKind>
public typealias GeneralAddress = SpecificAddress<GeneralAddressKind>

public enum GeneralAddressKind: SpecificAddressKind {
        public static let type: AddressType = .general
}

public enum ComponentAddressKind: SpecificAddressKind {
        public static let type: AddressType = .component
}

public enum ResourceAddressKind: SpecificAddressKind {
        public static let type: AddressType = .resource
}

public enum PackageAddressKind: SpecificAddressKind {
        public static let type: AddressType = .package
}

public enum AccountAddressKind: SpecificAddressKind {
        public static let type: AddressType = .account
}

public protocol SpecificAddressKind: Sendable {
        static var type: AddressType { get }
}

public struct SpecificAddress<Kind: SpecificAddressKind>: AddressProtocol, Sendable , Hashable {
        public let type: AddressType = Kind.type
        public let address: String
        
        // MARK: Init
        
        public init(address: String) {
                self.address = address
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
