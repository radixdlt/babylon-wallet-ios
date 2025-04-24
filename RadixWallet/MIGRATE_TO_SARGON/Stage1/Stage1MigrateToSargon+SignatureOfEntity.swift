import Foundation
import Sargon

// MARK: - SignatureOfEntity
struct SignatureOfEntity: Sendable, Hashable {
	let ownedFactorInstance: OwnedFactorInstance
	let signatureWithPublicKey: SignatureWithPublicKey
}
