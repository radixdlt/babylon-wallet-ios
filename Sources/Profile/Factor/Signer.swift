import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - ExpectedAccountGotPersona
struct ExpectedAccountGotPersona: Swift.Error {}

// MARK: - ExpectedPersonaGotAccount
struct ExpectedPersonaGotAccount: Swift.Error {}

// MARK: - Signer
// FIXME: move elsewhere. not really part of Profile... but.. where? We need some kind of shared target for higher level models that can depend on Profile. We lack such a package right now.
public struct Signer: Sendable, Hashable, Identifiable {
	public typealias ID = Entity
	public var id: ID { entity }
	public let entity: Entity

	public enum Entity: Sendable, Hashable, EntityBaseProtocol {
		case account(Profile.Network.Account)
		case persona(Profile.Network.Persona)
		public var factorInstances: Set<FactorInstance> {
			property(\.factorInstances)
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
			case let .account(entity): return entity[keyPath: keyPath]
			case let .persona(entity): return entity[keyPath: keyPath]
			}
		}

		/// A required non empty display name, used by presentation layer and sent to Dapps when requested.
		public var displayName: NonEmpty<String> {
			property(\.displayName)
		}
	}

	public let factorInstancesRequiredToSign: Set<FactorInstance>

	init(factorInstancesRequiredToSign: Set<FactorInstance>, of entity: Entity) throws {
		guard entity.factorInstances.isSuperset(of: factorInstancesRequiredToSign) else {
			struct FoundUnrelatedFactorInstances: Swift.Error {}
			throw FoundUnrelatedFactorInstances()
		}
		self.factorInstancesRequiredToSign = factorInstancesRequiredToSign
		self.entity = entity
	}

	public init(
		factorInstanceRequiredToSign: FactorInstance,
		entity: Entity
	) throws {
		try self.init(factorInstancesRequiredToSign: [factorInstanceRequiredToSign], of: entity)
	}
}
