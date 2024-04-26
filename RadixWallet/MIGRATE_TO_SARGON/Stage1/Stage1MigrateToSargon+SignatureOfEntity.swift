import Foundation
import Sargon

// MARK: - SignatureOfEntity
public struct SignatureOfEntity: Sendable, Hashable {
	public let signerEntity: AccountOrPersona
	public let derivationPath: DerivationPath
	public let factorSourceID: FactorSourceID
	public let signatureWithPublicKey: SignatureWithPublicKey

	public init(
		signerEntity: AccountOrPersona,
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
