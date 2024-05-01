import Foundation
import Sargon

// MARK: - Signer
// FIXME: move elsewhere. not really part of Profile... but.. where? We need some kind of shared target for higher level models that can depend on Profile. We lack such a package right now.
public struct Signer: Sendable, Hashable, Identifiable {
	public typealias ID = AccountOrPersona
	public var id: ID { entity }
	public let entity: AccountOrPersona

	public let factorInstancesRequiredToSign: Set<HierarchicalDeterministicFactorInstance>

	init(
		factorInstancesRequiredToSign: Set<HierarchicalDeterministicFactorInstance>,
		of entity: AccountOrPersona
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
		entity: AccountOrPersona
	) throws {
		try self.init(
			factorInstancesRequiredToSign: [
				factorInstanceRequiredToSign,
			],
			of: entity
		)
	}
}
