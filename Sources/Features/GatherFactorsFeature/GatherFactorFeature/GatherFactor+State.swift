import FeaturePrelude

// MARK: - GatherFactor.State
public extension GatherFactor {
	struct State: Sendable, Equatable, Identifiable {
		public let purpose: Purpose
		public let factorSource: FactorSource

		public init(
			purpose: Purpose,
			factorSource: FactorSource
		) {
			self.purpose = purpose
			self.factorSource = factorSource
		}
	}
}

public extension GatherFactor.State {
	typealias ID = FactorSourceID
	var id: ID { factorSource.any().factorSourceID }
}

// #if DEBUG
// public extension GatherFactor.State where Purpose == GatherFactorPurposeDerivePublicKey {
//	static let previewValue: Self = try! .init(
//        purpose: ,
//		factorSource: .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource(.init(mnemonic: .generate()))
//	)
// }
// #endif
