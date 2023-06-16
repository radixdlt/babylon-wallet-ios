import CasePaths
import Foundation

public typealias Address = SpecificAddress<GeneralAddressKind>

// public typealias EntityAddress = SpecificAddress<EntityAddressKind>

public typealias PackageAddress = SpecificAddress<PackageAddressKind>
public typealias ResourceAddress = SpecificAddress<ResourceAddressKind>

public typealias ComponentAddress = SpecificAddress<ComponentAddressKind>
public typealias AccountAddress = SpecificAddress<AccountAddressKind>
public typealias IdentityAddress = SpecificAddress<IdentityAddressKind>
public typealias AccessControllerAddress = SpecificAddress<AccessControllerAddressKind>
public typealias ConsensusManagerAddress = SpecificAddress<ConsensusManagerAddressKind>
public typealias GenericComponentAddress = SpecificAddress<GenericComponentAddressKind>
public typealias VaultAddress = SpecificAddress<VaultAddressKind>
public typealias ValidatorAddress = SpecificAddress<ValidatorAddressKind>
public typealias KeyValueStoreAddress = SpecificAddress<KeyValueStoreAddressKind>

// MARK: - GeneralAddressKind
public enum GeneralAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKind> = Set(AddressKind.allCases)
}

// MARK: - ResourceAddressKind
public enum ResourceAddressKind: SpecificAddressKind {
	// Is this valid? to check
	public static let addressSpace: Set<AddressKind> = [.globalFungibleResourceManager, .globalNonFungibleResourceManager]
}

// MARK: - PackageAddressKind
public enum PackageAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKind> = [.globalPackage]
}

// MARK: - ComponentAddressKind
public enum ComponentAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKind> = AccountAddressKind.addressSpace
		.union(IdentityAddressKind.addressSpace)
		.union(AccessControllerAddressKind.addressSpace)
		.union(ConsensusManagerAddressKind.addressSpace)
		.union(GenericComponentAddressKind.addressSpace)
		.union(VaultAddressKind.addressSpace)
		.union(ValidatorAddressKind.addressSpace)
		.union(KeyValueStoreAddressKind.addressSpace)
}

// MARK: - EntityAddressKind
public enum EntityAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKind> = AccountAddressKind.addressSpace.union(IdentityAddressKind.addressSpace)
}

// MARK: - AccountAddressKind
public enum AccountAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKind> = [.globalAccount, .internalAccount, .globalVirtualEd25519Account, .globalVirtualSecp256k1Account]
}

// MARK: - IdentityAddressKind
public enum IdentityAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKind> = [.globalIdentity, .globalVirtualEd25519Identity, .globalVirtualSecp256k1Identity]
}

// MARK: - AccessControllerAddressKind
public enum AccessControllerAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKind> = [.globalAccessController]
}

// MARK: - ConsensusManagerAddressKind
public enum ConsensusManagerAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKind> = [.globalConsensusManager]
}

// MARK: - GenericComponentAddressKind
public enum GenericComponentAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKind> = [.globalGenericComponent, .internalGenericComponent]
}

// MARK: - VaultAddressKind
public enum VaultAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKind> = [.internalFungibleVault, .internalNonFungibleVault]
}

// MARK: - ValidatorAddressKind
public enum ValidatorAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKind> = [.globalValidator]
}

// MARK: - KeyValueStoreAddressKind
public enum KeyValueStoreAddressKind: SpecificAddressKind {
	public static let addressSpace: Set<AddressKind> = [.internalKeyValueStore]
}

// MARK: - SpecificAddressKind
public protocol SpecificAddressKind: Sendable {
	/// The valid address space that can match a given kind of addresses
	static var addressSpace: Set<AddressKind> { get }
}

// MARK: - SpecificAddress
public struct SpecificAddress<Kind: SpecificAddressKind>: Sendable, Hashable, Identifiable {
	public struct InvalidAddress: Error, LocalizedError {
		let decodedKind: AddressKind
		let addressSpace: Set<AddressKind>

		public var errorDescription: String? {
			"Decoded AddressKind -> \(decodedKind), not found in the expected address space \(addressSpace)"
		}
	}

	public var id: String {
		address
	}

	public let address: String
	public let decodedKind: AddressKind

	//        #if DEBUG
	init(address: String, decodedKind: AddressKind) {
		self.address = address
		self.decodedKind = decodedKind
	}

//
	//        public init(stringLiteral value: String) {
	//                self.init(address: value)
	//        }
	//        #endif

	public init(validatingAddress address: String) throws {
		let decodedAddress = try RadixEngine.instance.decodeAddressRequest(request: .init(address: address)).get()
		guard Kind.addressSpace.contains(decodedAddress.entityType) else {
			throw InvalidAddress(decodedKind: decodedAddress.entityType, addressSpace: Kind.addressSpace)
		}
		self.init(address: address, decodedKind: decodedAddress.entityType)
	}
}

// MARK: ValueProtocol
extension SpecificAddress: ValueProtocol {
	public static var kind: ManifestASTValueKind { .address }
	public static var casePath: CasePath<ManifestASTValue, SpecificAddress<Kind>> {
		.init {
			.address($0.asGeneral())
		} extract: {
			guard case let .address(address) = $0 else {
				return nil
			}

			return try? SpecificAddress<Kind>.init(validatingAddress: address.address)
		}
	}
}

extension CodingUserInfoKey {
	static let retCoding = CodingUserInfoKey(rawValue: "RETCoding")!
}

// MARK: - SpecificAddress + Codable
extension SpecificAddress: Codable {
	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(address)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		try self.init(validatingAddress: container.decode(String.self))
	}
}

// MARK: - SpecificAddress + CustomStringConvertible
extension SpecificAddress: CustomStringConvertible {
	public var description: String {
		address
	}
}

extension SpecificAddress {
	public func asGeneral() -> Address {
		.init(address: address, decodedKind: decodedKind)
	}
}

extension AccountAddress {
	public var asComponentAddress: ComponentAddress {
		.init(address: address, decodedKind: decodedKind)
	}
}
