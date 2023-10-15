import EngineToolkit

// MARK: - SignatureOfEntity
public struct SignatureOfEntity: Sendable, Hashable {
	public let signerEntity: EntityPotentiallyVirtual
	public let derivationPath: DerivationPath
	public let factorSourceID: FactorSourceID
	public let signatureWithPublicKey: SignatureWithPublicKey

	public init(
		signerEntity: EntityPotentiallyVirtual,
		derivationPath: DerivationPath,
		factorSourceID: FactorSourceID,
		signatureWithPublicKey: SignatureWithPublicKey
	) {
		self.signerEntity = signerEntity
		self.derivationPath = derivationPath
		self.factorSourceID = factorSourceID
		self.signatureWithPublicKey = signatureWithPublicKey
	}
}
