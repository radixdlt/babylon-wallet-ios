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
}
