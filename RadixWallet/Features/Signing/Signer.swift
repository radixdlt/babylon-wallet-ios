import Foundation
import Sargon

// MARK: - Signer
// FIXME: move elsewhere. not really part of Profile... but.. where? We need some kind of shared target for higher level models that can depend on Profile. We lack such a package right now.
struct Signer: Sendable, Hashable, Identifiable {
	typealias ID = AccountOrPersona
	var id: ID { entity }
	let entity: AccountOrPersona

	let factorInstancesRequiredToSign: Set<HierarchicalDeterministicFactorInstance>

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

	init(
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
