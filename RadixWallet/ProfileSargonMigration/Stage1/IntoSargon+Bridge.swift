import CryptoKit
import Foundation
import Sargon
import SargonUniFFI

extension OnLedgerEntitiesClient.StakeClaim {
	public func intoSargon() -> StakeClaim {
		StakeClaim(
			validatorAddress: self.validatorAddress,
			resourceAddress: self.token.id.resourceAddress.asNonFungibleResourceAddress!,
			ids: [self.id.nonFungibleLocalId],
			amount: self.claimAmount.nominalAmount
		)
	}
}

extension Curve25519.Signing.PublicKey {
	func intoSargon() -> Ed25519PublicKey {
		try! Ed25519PublicKey(bytes: self.compressedRepresentation)
	}
}
