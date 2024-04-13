import Foundation
import Sargon

public typealias FactorSourceIDFromHash = FactorSourceIdFromHash

extension Sargon.HierarchicalDeterministicFactorInstance {
	public var factorSourceID: FactorSourceIDFromHash {
		self.factorSourceId
	}

	public var derivationPath: Sargon.DerivationPath {
		self.publicKey.derivationPath
	}

	public var factorInstance: FactorInstance {
		FactorInstance(
			factorSourceId: factorSourceID.embed(),
			badge: .virtual(
				value: .hierarchicalDeterministic(value: self.publicKey)
			)
		)
	}
}
