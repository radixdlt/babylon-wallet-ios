import CryptoKit
import Foundation
import Sargon
import SargonUniFFI

extension OnLedgerEntitiesClient.StakeClaim {
	public func intoSargon() -> StakeClaim {
		StakeClaim(
			validatorAddress: validatorAddress,
			resourceAddress: token.id.resourceAddress.asNonFungibleResourceAddress!,
			ids: [id.nonFungibleLocalId],
			amount: claimAmount.nominalAmount
		)
	}
}

extension Curve25519.Signing.PublicKey {
	func intoSargon() -> Ed25519PublicKey {
		try! Ed25519PublicKey(bytes: compressedRepresentation)
	}
}
