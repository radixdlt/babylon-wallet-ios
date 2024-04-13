import CryptoKit
import Foundation
import Sargon
import SargonUniFFI

extension OnLedgerEntitiesClient.StakeClaim {
	public func intoSargon() -> Sargon.StakeClaim {
		Sargon.StakeClaim(
			validatorAddress: self.validatorAddress,
			resourceAddress: self.token.id.resourceAddress.asNonFungibleResourceAddress!,
			ids: [self.id.nonFungibleLocalId],
			amount: self.claimAmount.nominalAmount
		)
	}
}

extension Curve25519.Signing.PublicKey {
	func intoSargon() -> Sargon.Ed25519PublicKey {
		try! Sargon.Ed25519PublicKey(bytes: self.compressedRepresentation)
	}
}
