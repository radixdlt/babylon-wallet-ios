import FeaturePrelude

// MARK: - GatherFactor.State
public extension GatherFactor {
	struct State: Sendable, Equatable, Identifiable {
		public let purpose: GatherFactorPurpose
		public let factorSource: FactorSource

		public init(
			purpose: GatherFactorPurpose,
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

#if DEBUG
public extension GatherFactor.State {
	static let previewValue: Self = try! .init(
		purpose: .previewValue,
		factorSource: .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource(.init(mnemonic: .generate()))
	)
}
#endif
