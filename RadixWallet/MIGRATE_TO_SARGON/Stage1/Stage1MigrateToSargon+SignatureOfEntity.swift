import Foundation
import Sargon

// MARK: - SignatureOfEntity
struct SignatureOfEntity: Hashable {
	let ownedFactorInstance: OwnedFactorInstance
	let signatureWithPublicKey: SignatureWithPublicKey
}
