import EngineToolkit

// MARK: - ExpectedAccountGotPersona
struct ExpectedAccountGotPersona: Swift.Error {}

// MARK: - ExpectedPersonaGotAccount
struct ExpectedPersonaGotAccount: Swift.Error {}

// MARK: - Signer
// FIXME: move elsewhere. not really part of Profile... but.. where? We need some kind of shared target for higher level models that can depend on Profile. We lack such a package right now.
public struct Signer: Sendable, Hashable, Identifiable {
	public typealias ID = EntityPotentiallyVirtual
	public var id: ID { entity }
	public let entity: EntityPotentiallyVirtual

	public let factorInstancesRequiredToSign: Set<HierarchicalDeterministicFactorInstance>

	init(
		factorInstancesRequiredToSign: Set<HierarchicalDeterministicFactorInstance>,
		of entity: EntityPotentiallyVirtual
	) throws {
		guard
			entity.virtualHierarchicalDeterministicFactorInstances
			.isSuperset(of: factorInstancesRequiredToSign)
		else {
			struct FoundUnrelatedFactorInstances: Swift.Error {}
			throw FoundUnrelatedFactorInstances()
		}
		self.factorInstancesRequiredToSign = factorInstancesRequiredToSign
		self.entity = entity
	}

	public init(
		factorInstanceRequiredToSign: HierarchicalDeterministicFactorInstance,
		entity: EntityPotentiallyVirtual
	) throws {
		try self.init(
			factorInstancesRequiredToSign: [
				factorInstanceRequiredToSign,
			],
			of: entity
		)
	}
}

// MARK: - EntityPotentiallyVirtual
public enum EntityPotentiallyVirtual: Sendable, Hashable, EntityBaseProtocol, Identifiable {
	public typealias ID = String
	public var id: ID { address }
	public var address: String {
		switch self {
		case let .account(entity): entity.address.address
		case let .persona(entity): entity.address.address
		}
	}

	case account(Profile.Network.Account)
	case persona(Profile.Network.Persona)
	public var virtualHierarchicalDeterministicFactorInstances: Set<HierarchicalDeterministicFactorInstance> {
		property(\.virtualHierarchicalDeterministicFactorInstances)
	}

	public func asAccount() throws -> Profile.Network.Account {
		switch self {
		case let .account(account): return account
		case .persona: throw ExpectedAccountGotPersona()
		}
	}

	public func asPersona() throws -> Profile.Network.Persona {
		switch self {
		case let .persona(persona): return persona
		case .account: throw ExpectedPersonaGotAccount()
		}
	}

	public var securityState: EntitySecurityState {
		property(\.securityState)
	}

	/// The ID of the network this entity exists on.
	public var networkID: NetworkID {
		property(\.networkID)
	}

	private func property<Property>(_ keyPath: KeyPath<EntityBaseProtocol, Property>) -> Property {
		switch self {
		case let .account(entity): entity[keyPath: keyPath]
		case let .persona(entity): entity[keyPath: keyPath]
		}
	}

	/// A required non empty display name, used by presentation layer and sent to Dapps when requested.
	public var displayName: NonEmpty<String> {
		property(\.displayName)
	}

	/// Flags that are currently set on entity.
	public var flags: Flags {
		property(\.flags)
	}
}

// MARK: - SigningPurpose
public enum SigningPurpose: Sendable, Hashable {
	case signAuth
	case signTransaction(SignTransactionPurpose)
	public enum SignTransactionPurpose: Sendable, Hashable {
		case manifestFromDapp
		case internalManifest(InternalTXSignPurpose)
		public enum InternalTXSignPurpose: Sendable, Hashable {
			case transfer
			case uploadAuthKey
			#if DEBUG
			/// E.g. turn account into dapp definition account type (setting metadata)
			case debugModifyAccount
			#endif
		}
	}
}
