import CryptoKit
import Foundation
import Sargon

extension OnLedgerEntitiesClient.StakeClaim {
	func intoSargon() -> StakeClaim {
		StakeClaim(
			validatorAddress: validatorAddress,
			resourceAddress: token.id.resourceAddress.asNonFungibleResourceAddress!,
			ids: [id.nonFungibleLocalId],
			amount: claimAmount.exactAmount?.nominalAmount ?? .zero
		)
	}
}

extension Curve25519.Signing.PublicKey {
	func intoSargon() -> Ed25519PublicKey {
		try! Ed25519PublicKey(bytes: compressedRepresentation)
	}
}
