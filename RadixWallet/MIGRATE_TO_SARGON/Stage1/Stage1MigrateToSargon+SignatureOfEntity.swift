import Foundation
import Sargon

// MARK: - SignatureOfEntity
struct SignatureOfEntity: Sendable, Hashable {
	let signerEntity: AccountOrPersona
	let derivationPath: DerivationPath
	let factorSourceID: FactorSourceID
	let signatureWithPublicKey: SignatureWithPublicKey

	init(
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

// MARK: - SignatureOfEntity2
struct SignatureOfEntity2: Sendable, Hashable {
	let ownedFactorInstance: OwnedFactorInstance
	let signatureWithPublicKey: SignatureWithPublicKey
}
